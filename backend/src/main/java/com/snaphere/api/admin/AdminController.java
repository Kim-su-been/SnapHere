package com.snaphere.api.admin;

import com.snaphere.api.auth.ExternalIds;
import com.snaphere.api.common.error.ErrorCode;
import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.CursorPage;
import com.snaphere.api.common.web.TraceIdFilter;
import com.snaphere.api.place.PlaceDtos;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {
    private final BatchService batches;
    private final AdminService admin;
    public AdminController(BatchService batches, AdminService admin) { this.batches=batches; this.admin=admin; }

    @PostMapping("/batches/{jobType}")
    ResponseEntity<ApiResponse<BatchDtos.BatchRun>> start(@PathVariable String jobType,
            @RequestBody(required=false) BatchDtos.StartRequest body,HttpServletRequest request){
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(ok(batches.start(jobType,body),request)); }

    @GetMapping("/batches/{runId}")
    ApiResponse<BatchDtos.BatchRun> run(@PathVariable String runId,HttpServletRequest request){
        return ok(batches.get(ExternalIds.parse(runId,"run", ErrorCode.COMMON_404)),request); }

    @GetMapping("/sync-logs")
    ApiResponse<CursorPage<BatchDtos.SyncLog>> logs(@RequestParam(required=false) String result,
            @RequestParam(required=false) String cursor,@RequestParam(defaultValue="20") int size,HttpServletRequest request){
        return ok(batches.logs(result,cursor,size),request); }

    @PatchMapping("/places/{placeId}/verify-radius")
    ApiResponse<PlaceDtos.PlaceDetail> placeRadius(@PathVariable String placeId,@Valid @RequestBody PlaceDtos.RadiusRequest body,HttpServletRequest request){
        return ok(admin.updatePlaceRadius(placeId,body.verifyRadiusM()),request); }

    @PatchMapping("/events/{eventId}/verify-radius")
    ApiResponse<Map<String,Object>> eventRadius(@PathVariable String eventId,@Valid @RequestBody PlaceDtos.EventRadiusRequest body,HttpServletRequest request){
        return ok(admin.updateEventRadius(eventId,body.verifyRadiusM()),request); }

    @PatchMapping("/regions/{areaCode}/event-radius")
    ApiResponse<PlaceDtos.Region> regionRadius(@PathVariable int areaCode,@Valid @RequestBody PlaceDtos.RegionRadiusRequest body,HttpServletRequest request){
        return ok(admin.updateRegionRadius(areaCode,body.defaultEventVerifyRadiusM()),request); }

    @PatchMapping("/events/{eventId}")
    ApiResponse<Map<String,Object>> event(@PathVariable String eventId,@Valid @RequestBody BatchDtos.AdminEventRequest body,HttpServletRequest request){
        return ok(admin.updateEvent(eventId,body),request); }

    @PatchMapping("/reports/{reportId}")
    ApiResponse<BatchDtos.ReportResult> report(@PathVariable String reportId,@Valid @RequestBody BatchDtos.ResolveReportRequest body,HttpServletRequest request){
        return ok(admin.resolveReport(reportId,body),request); }

    @PostMapping("/places/{placeId}/moderation")
    ResponseEntity<ApiResponse<BatchDtos.BatchRun>> moderate(@PathVariable String placeId,@Valid @RequestBody BatchDtos.ModerationRequest body,HttpServletRequest request){
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(ok(admin.moderate(placeId,body),request)); }

    private static <T> ApiResponse<T> ok(T data,HttpServletRequest request){return ApiResponse.ok(data, TraceIdFilter.currentTraceId(request));}
}
