# yamareco_to_garmin
Convert the gpx downloaded from the Yamareco mountaineering plan so that it can be read by Garmin Connect in a nice way.

## USAGE
```
ruby yamareco_to_garmin.rb -i file_from_yamareco.gpx -o file_to_garmin.gpx

Usage: yamareco_to_garmin [options]
    -i YAMARECO_GPX_FILE,            specify gpx file downloaded from yamareco.
        --input-file
    -o [GARMIN_GPX_FILE],            specify output file. if no specify, output it to stdout.
        --output-file
        --[no-]elevation             [do not] add elevation into name.
        --[no-]yomi                  [do not] add yomi into name.
```


## feature
- Convert the place names in the gpx file downloaded from Yamareco's “地名入りのGPXファイルをダウンロード” to course points in Garmin Connect
- Convert Yamareco place name types to course point types according to the conversion table below. Since a place name in Yamareco can contain multiple types, whereas a course point in Garmin Connect can only contain one type, the conversion is done from the top of the conversion table to the matching one.
    - type:1 (頂上) -> 山頂/峠(SUMMIT)
    - type:2 (峠) -> 山頂/峠(SUMMIT)
    - type:3 (分岐) -> チェックポイント(CHECKPOINT)
    - type:4 (登山口) -> チェックポイント(CHECKPOINT)
    - type:5 (山小屋) -> 休憩エリア(REST AREA)
    - type:6 (テント場) -> キャンプ場(CAMPSITE)
    - type:7 (水場) -> ウォーター(WATER)
    - type:9 (お風呂) -> 休憩エリア(REST AREA)
    - type:11(展望ポイント) -> 展望スポット(OVERLOOK)
    - type:12(バス停) -> 交通機関(TRANSPORT)
    - type:13(駐車場) -> 交通機関(TRANSPORT)
    - type:14(トイレ) -> トイレ(TOILET)
    - type:なし -> チェックポイント(CHECKPOINT)
- Include altitude in place names registered as course points
- Add yomi to place names registered as course points.
- Split files when converting files planned for multiple days

## Attention
- Not intended for use with Garmin BaseCamp.
