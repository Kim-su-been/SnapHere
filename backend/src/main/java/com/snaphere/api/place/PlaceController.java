package com.snaphere.api.place;

import com.snaphere.api.auth.CurrentActor;
import com.snaphere.api.common.web.ApiResponse;
import com.snaphere.api.common.web.CursorPage;
import com.snaphere.api.common.web.TraceIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class PlaceController {
    private final PlaceService service;
    public PlaceController(PlaceService service) { this.service = service; }

    @GetMapping("/regions")
    ApiResponse<List<PlaceDtos.Region>> regions(HttpServletRequest request) {
        return ok(service.regions(), request);
    }

    @GetMapping("/regions/{areaCode}/sigungu")
    ApiResponse<List<PlaceDtos.Sigungu>> sigungu(@PathVariable int areaCode, HttpServletRequest request) {
        return ok(service.sigungu(areaCode), request);
    }

    @GetMapping("/places")
    ApiResponse<CursorPage<PlaceDtos.PlaceSummary>> places(
            @RequestParam(required = false) Integer areaCode,
            @RequestParam(required = false) Integer sigunguCode,
            @RequestParam(required = false) Integer contentTypeId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication, HttpServletRequest request) {
        return ok(service.list(areaCode, sigunguCode, contentTypeId, keyword, cursor, size,
                CurrentActor.optional(authentication)), request);
    }

    @GetMapping("/places/nearby")
    ApiResponse<PlaceDtos.NearbyPlaceResult> nearby(@RequestParam double lat, @RequestParam double lng,
                                                     @RequestParam(defaultValue = "500") int radiusM,
                                                     Authentication authentication, HttpServletRequest request) {
        return ok(service.nearby(lat, lng, radiusM, CurrentActor.optional(authentication)), request);
    }

    @GetMapping("/places/{placeId}")
    ApiResponse<PlaceDtos.PlaceDetail> detail(@PathVariable String placeId,
                                               @RequestHeader(name = "Accept-Language", required = false) String language,
                                               Authentication authentication, HttpServletRequest request) {
        return ok(service.detail(placeId, language, CurrentActor.optional(authentication)), request);
    }

    @GetMapping("/places/{placeId}/posts")
    ApiResponse<CursorPage<PlaceDtos.PostSummary>> posts(@PathVariable String placeId,
                                                          @RequestParam(required = false) String cursor,
                                                          @RequestParam(defaultValue = "20") int size,
                                                          Authentication authentication, HttpServletRequest request) {
        return ok(service.posts(placeId, cursor, size, CurrentActor.optional(authentication)), request);
    }

    @PostMapping("/places")
    ResponseEntity<ApiResponse<PlaceDtos.CreatePlaceResult>> create(Authentication authentication,
                                                                    @Valid @RequestBody PlaceDtos.CreatePlaceRequest body,
                                                                    HttpServletRequest request) {
        var result = service.create(CurrentActor.required(authentication), body);
        return ResponseEntity.status(result.created() ? HttpStatus.CREATED : HttpStatus.OK)
                .body(ok(result, request));
    }

    @PutMapping("/places/{placeId}/bookmark")
    ApiResponse<PlaceDtos.BookmarkResult> bookmark(Authentication authentication, @PathVariable String placeId,
                                                    HttpServletRequest request) {
        return ok(service.bookmark(CurrentActor.required(authentication), placeId), request);
    }

    @DeleteMapping("/places/{placeId}/bookmark")
    ApiResponse<PlaceDtos.BookmarkResult> unbookmark(Authentication authentication, @PathVariable String placeId,
                                                      HttpServletRequest request) {
        return ok(service.unbookmark(CurrentActor.required(authentication), placeId), request);
    }

    @GetMapping("/me/bookmarks")
    ApiResponse<CursorPage<PlaceDtos.PlaceSummary>> bookmarks(Authentication authentication,
                                                               @RequestParam(defaultValue = "PLACE") String type,
                                                               @RequestParam(required = false) String cursor,
                                                               @RequestParam(defaultValue = "20") int size,
                                                               HttpServletRequest request) {
        if (!"PLACE".equals(type)) throw new com.snaphere.api.common.error.ApiException(com.snaphere.api.common.error.ErrorCode.COMMON_400);
        return ok(service.bookmarks(CurrentActor.required(authentication), cursor, size), request);
    }

    @GetMapping("/tags/suggestions")
    ApiResponse<List<PlaceDtos.TagSuggestion>> tags(@RequestParam String placeId,
                                                     @RequestParam(required = false) String query,
                                                     HttpServletRequest request) {
        return ok(service.tags(placeId, query), request);
    }

    @PostMapping("/places/{placeId}/reports")
    ResponseEntity<ApiResponse<PlaceDtos.ReportReceipt>> report(Authentication authentication,
                                                                 @PathVariable String placeId,
                                                                 @Valid @RequestBody PlaceDtos.CreateReportRequest body,
                                                                 HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ok(service.report(CurrentActor.required(authentication), placeId, body), request));
    }

    private static <T> ApiResponse<T> ok(T data, HttpServletRequest request) {
        return ApiResponse.ok(data, TraceIdFilter.currentTraceId(request));
    }
}
