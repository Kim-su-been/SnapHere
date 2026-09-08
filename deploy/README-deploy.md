# SnapHere 배포 가이드

Lightsail 2GB 한 대에 모놀리식으로 올린다. **빌드는 GitHub Actions 에서, 서버는
완성된 `app.jar` 만 받아 재시작**한다.

> 2GB 인스턴스에서 Gradle 을 돌리면 OOM 으로 앱까지 같이 죽는다. 그래서 서버에는
> 컴파일러가 없고, 러너(램 16GB)가 만든 jar 를 scp 로 받는다.

이 문서에 나오는 `<서버IP>`, `<도메인>`, `<사용자>` 는 자리표시자다. **저장소가
public 이므로 실제 값을 이 문서나 `.env.example` 에 적지 말 것.** 실제 서버 주소는
GitHub Secrets 에만 둔다.

## 파일 구성

```
저장소                                  서버 ~/snaphere/
├─ compose.yml            ← 로컬 개발용, 서버로 올리지 않음
├─ deploy/
│  ├─ docker-compose.prod.yml  ──────→  docker-compose.yml   ← 이름을 바꿔서 둔다
│  ├─ Dockerfile               ──────→  Dockerfile
│  ├─ .dockerignore            ──────→  .dockerignore
│  ├─ .env.example             ──────→  .env  (값을 채워서)
│  ├─ nginx/conf.d/api.conf    ──────→  nginx/conf.d/api.conf
│  └─ nginx/conf.d/proxy-headers.inc → nginx/conf.d/proxy-headers.inc
└─ .github/workflows/
   ├─ deploy.yml          ← main push 시 배포
   └─ test.yml            ← PR 시 테스트
```

`docker-compose.prod.yml` 을 서버에서 `docker-compose.yml` 이라는 이름으로 두는
이유는 그래야 `docker compose` 명령이 `-f` 없이 그냥 돌기 때문이다. `deploy.yml`
워크플로의 재시작 단계도 `-f` 를 안 붙인다.

---

# 1단계 · 배포용 SSH 키 만들기 (PowerShell)

Actions 가 서버에 접속할 전용 키다. 평소 쓰는 개인 키를 GitHub Secrets 에 넣지 말고
배포용을 따로 만든다.

```powershell
ssh-keygen -t ed25519 -C "github-actions-snaphere" -f "$env:USERPROFILE\.ssh\snaphere_deploy" -N '""'
```

`-N '""'` 은 암호 없는 키를 만든다는 뜻이다. Actions 는 암호를 입력할 사람이 없으니
암호가 없어야 한다. 그래서 이 키는 GitHub Secrets 밖으로 절대 나가면 안 된다.

두 파일이 생긴다.

| 파일 | 용도 |
|---|---|
| `snaphere_deploy` | **개인키** → GitHub Secrets 에 넣는다 |
| `snaphere_deploy.pub` | 공개키 → 서버에 넣는다 |

공개키 내용을 확인한다 (2단계에서 붙여넣는다).

```powershell
Get-Content "$env:USERPROFILE\.ssh\snaphere_deploy.pub"
```

# 2단계 · 서버에 공개키 등록

Lightsail 콘솔에서 받은 기본 키로 접속한다.

```powershell
ssh -i "<다운로드한 lightsail 키 경로>" <사용자>@<서버IP>
```

접속된 **서버 안에서**:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "<1단계에서 복사한 공개키 한 줄>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

PowerShell 로 돌아와 새 키로 접속되는지 확인한다.

```powershell
ssh -i "$env:USERPROFILE\.ssh\snaphere_deploy" <사용자>@<서버IP> "echo 접속OK"
```

`접속OK` 가 찍히면 된다. 안 되면 3단계로 넘어가지 말 것 — Actions 도 똑같이 실패한다.

# 3단계 · 서버 준비 (서버 안에서)

## Docker 설치

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

그룹 변경은 재로그인해야 적용된다. `exit` 후 다시 접속한다.

```bash
docker compose version
```

## 스왑 2GB

**이 단계를 건너뛰면 첫 배포에서 앱이 죽는다.** 2GB 중 postgres·redis·nginx 가
830m 을 쓰고 JVM 힙이 700m 이다. 여유가 거의 없어서 순간 피크에 OOM Killer 가
컨테이너를 죽인다.

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

`Swap` 줄에 2.0Gi 가 보이면 된다.

## 방화벽

Lightsail 콘솔 > 인스턴스 > **네트워킹** 탭에서 IPv4 방화벽에 열어둘 것:

| 포트 | 용도 |
|---|---|
| 22 | SSH |
| 80 | HTTP (인증서 발급에도 필요) |
| 443 | HTTPS |

**5432 와 6379 는 열지 않는다.** compose 가 포트를 밖으로 노출하지 않으므로 열어도
닿지 않지만, 열어두면 스캐너를 끌어들인다.

# 4단계 · 배포 파일 서버로 복사 (PowerShell)

저장소 루트에서 실행한다.

```powershell
ssh -i "$env:USERPROFILE\.ssh\snaphere_deploy" <사용자>@<서버IP> "mkdir -p ~/snaphere/nginx/conf.d ~/snaphere/certbot/www ~/snaphere/certbot/conf"

scp -i "$env:USERPROFILE\.ssh\snaphere_deploy" deploy/docker-compose.prod.yml <사용자>@<서버IP>:~/snaphere/docker-compose.yml
scp -i "$env:USERPROFILE\.ssh\snaphere_deploy" deploy/Dockerfile deploy/.dockerignore deploy/.env.example <사용자>@<서버IP>:~/snaphere/
scp -i "$env:USERPROFILE\.ssh\snaphere_deploy" deploy/nginx/conf.d/api.conf deploy/nginx/conf.d/proxy-headers.inc <사용자>@<서버IP>:~/snaphere/nginx/conf.d/
```

첫 번째 줄에서 `certbot/www` 와 `certbot/conf` 를 미리 만드는 이유는, compose 가 이
경로를 `:ro` 로 마운트하는데 없으면 도커가 **디렉터리로 새로 만들어 root 소유**로
두고 나중에 certbot 이 못 쓰기 때문이다.

# 5단계 · `.env` 채우기 (서버 안에서)

```bash
cd ~/snaphere
cp .env.example .env
nano .env
chmod 600 .env
```

비밀번호와 JWT 시크릿은 서버에서 바로 만든다.

```bash
openssl rand -base64 24   # POSTGRES_PASSWORD
openssl rand -base64 48   # SNAPHERE_JWT_SECRET
```

**이름을 바꾸지 말 것.** `SNAPHERE_JWT_SECRET` 을 `JWT_SECRET` 으로 적으면 앱이
읽지 못하고 시크릿이 빈 값이 되어 인증 전체가 실패한다. `GOOGLE_OAUTH_CLIENT_ID`
도 `GOOGLE_CLIENT_ID` 가 아니다. `.env.example` 의 주석에 이유가 적혀 있다.

# 6단계 · 첫 기동 (서버 안에서)

app 이미지는 `app.jar` 를 필요로 한다. 아직 Actions 를 안 돌렸으면 DB·Redis·nginx
먼저 띄운다.

```bash
cd ~/snaphere
docker compose up -d postgres redis nginx
docker compose ps
```

`postgres` 와 `redis` 가 `healthy` 가 될 때까지 20초쯤 걸린다.

## HTTPS 인증서 (도메인이 있을 때만)

도메인의 A 레코드를 서버 IP 로 먼저 걸어둔다. 그다음:

```bash
docker run --rm \
  -v ~/snaphere/certbot/conf:/etc/letsencrypt \
  -v ~/snaphere/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d <도메인> --email <메일> --agree-tos --no-eff-email
```

발급이 끝나면 `nginx/conf.d/api.conf` 아래쪽의 HTTPS `server` 블록 주석을 해제하고
`<도메인>` 을 채운 뒤 reload 한다.

```bash
docker compose exec nginx nginx -t      # 문법 검사 먼저
docker compose exec nginx nginx -s reload
```

> 인증서 파일이 없는 상태로 443 블록을 켜면 nginx 가 기동에 실패한다
> (`cannot load certificate`). 반드시 발급을 먼저 끝낼 것.

# 7단계 · GitHub Secrets 등록 (웹 화면)

**이건 파일로 만들어 커밋하는 게 아니다.** 저장소 > **Settings** >
**Secrets and variables** > **Actions** > **New repository secret** 에서 웹으로 넣는다.

| 이름 | 값 |
|---|---|
| `SSH_PRIVATE_KEY` | `snaphere_deploy` 파일 **전체 내용** (`-----BEGIN` ~ `-----END` 줄 포함) |
| `SERVER_HOST` | 서버 공인 IP |
| `SERVER_USER` | 서버 로그인 사용자명 |

개인키 내용을 클립보드로 바로 복사한다 (PowerShell):

```powershell
Get-Content "$env:USERPROFILE\.ssh\snaphere_deploy" -Raw | Set-Clipboard
```

워크플로에서는 `${{ secrets.SSH_PRIVATE_KEY }}` 로 참조만 하고, 실행 로그에는
`***` 로 마스킹돼서 찍히지 않는다.

# 8단계 · 배포

`main` 에 push 하면 `deploy.yml` 이 돈다. 수동으로 돌리려면 저장소 > **Actions** >
**Deploy to Lightsail** > **Run workflow**.

워크플로가 하는 일:

1. JDK 21 세팅 후 `./gradlew clean bootJar` (테스트는 안 돌린다 — `test.yml` 담당)
2. `build/libs` 에서 `-plain.jar` 아닌 실행 가능한 jar 를 골라 `app.jar` 로 복사
3. `scp` 로 `~/snaphere/app.jar` 에 업로드
4. `docker compose up -d --build app` 으로 이미지 재빌드 + 재시작
5. `/actuator/health` 가 200 이 될 때까지 최대 3분 대기

> ⚠ **현재 `deploy.yml` 은 `on: push: branches: [main]` 이다.** 이 저장소의 기본
> 브랜치는 `develop` 이라, `main` 에 머지하지 않으면 배포가 돌지 않는다. `develop`
> push 마다 배포하려면 `deploy.yml` 의 `branches` 를 고칠 것.

---

# 운영 명령 모음

## PowerShell 에서 (내 PC)

```powershell
# 서버 접속
ssh -i "$env:USERPROFILE\.ssh\snaphere_deploy" <사용자>@<서버IP>

# 접속 없이 로그만 보기
ssh -i "$env:USERPROFILE\.ssh\snaphere_deploy" <사용자>@<서버IP> "cd ~/snaphere && docker compose logs --tail=200 app"

# 헬스체크
curl.exe http://<서버IP>/actuator/health
```

접속을 매번 길게 치지 않으려면 `~\.ssh\config` 에 등록한다.

```powershell
notepad "$env:USERPROFILE\.ssh\config"
```

```
Host snaphere
    HostName <서버IP>
    User <사용자>
    IdentityFile ~/.ssh/snaphere_deploy
```

그러면 `ssh snaphere` 만으로 접속된다.

## 서버에서

```bash
cd ~/snaphere

docker compose ps                        # 상태
docker compose logs -f app               # 앱 로그 실시간
docker compose logs --tail=200 app       # 최근 200줄
docker compose restart app               # 앱만 재시작
docker compose down                      # 전체 정지 (데이터 유지)
docker stats --no-stream                 # 컨테이너별 메모리 실사용

# DB 접속
docker compose exec postgres psql -U snaphere -d snaphere

# Redis 확인 (키 세 종류만 나와야 정상)
docker compose exec redis redis-cli --scan --pattern '*' | head -20
```

## 자주 겪는 문제

| 증상 | 원인 |
|---|---|
| `docker compose up` 이 `app.jar not found` 로 실패 | Actions 가 아직 안 돌았다. 4~7단계를 끝내고 8단계 실행 |
| health 가 3분 내내 000 | app 컨테이너가 안 떴다. `docker compose logs app` 확인 |
| 로그에 `jwt-secret` 관련 오류 | `.env` 의 이름이 `SNAPHERE_JWT_SECRET` 이 맞는지 확인 (5단계) |
| 이미지 업로드가 에러 없이 안 올라감 | `MEDIA_PROVIDER=s3` 누락. 기본값 `stub` 이면 스텁 동작만 한다 |
| 구글 로그인만 실패 | `GOOGLE_OAUTH_CLIENT_ID` 이름 확인 |
| app 이 자꾸 재시작 | 스왑 미설정(3단계) 또는 `-Xmx` 초과. `docker stats` 로 확인 |
| nginx 가 기동 실패 | 인증서 없이 443 블록을 켰다. `api.conf` 의 HTTPS 블록 다시 주석 처리 |
