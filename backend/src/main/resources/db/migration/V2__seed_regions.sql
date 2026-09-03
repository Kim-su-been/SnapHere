INSERT INTO regions(area_code, name_ko, name_en, default_event_verify_radius_m) VALUES
 (1, '서울', 'Seoul', 2000), (2, '인천', 'Incheon', 2000),
 (3, '대전', 'Daejeon', 2000), (4, '대구', 'Daegu', 2000),
 (5, '광주', 'Gwangju', 2000), (6, '부산', 'Busan', 2000),
 (7, '울산', 'Ulsan', 2000), (8, '세종', 'Sejong', 2000),
 (31, '경기', 'Gyeonggi-do', 2000), (32, '강원', 'Gangwon-do', 2000),
 (33, '충북', 'Chungcheongbuk-do', 2000), (34, '충남', 'Chungcheongnam-do', 2000),
 (35, '경북', 'Gyeongsangbuk-do', 2000), (36, '경남', 'Gyeongsangnam-do', 2000),
 (37, '전북', 'Jeonbuk-do', 2000), (38, '전남', 'Jeollanam-do', 2000),
 (39, '제주', 'Jeju-do', 2000)
ON CONFLICT (area_code) DO UPDATE SET name_ko=excluded.name_ko, name_en=excluded.name_en;
