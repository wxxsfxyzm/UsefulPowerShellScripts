# 获取当前目录下的所有视频文件和字幕文件
$videoFiles = Get-ChildItem | Where-Object {$_.Name -match "\.(mkv|mp4)$"}
$subtitleFiles = Get-ChildItem | Where-Object {$_.Name -match "\.(ass|srt)$"}

Write-Host "Found $($videoFiles.Count) video files and $($subtitleFiles.Count) subtitle files."

foreach ($subtitle in $subtitleFiles) {
    Write-Host "Processing subtitle: '$($subtitle.Name)'"

    # 跳过已经处理过的字幕文件（以 NxN 格式命名）
    if ($subtitle.Name -match " - ([0-9]+)x([0-9]{1,2}) - ") {
        Write-Host "Skipping already processed subtitle: '$($subtitle.Name)'"
        continue
    }

    # 只处理包含 SXXEYY 格式的字幕
    if ($subtitle.Name -match "\[S(\d{2})E(\d{2})\]") {
        $season = [int]$matches[1]  # 转换为整数以去掉前导零
        $episode = [int]$matches[2]  # 转换为整数以去掉前导零
        $formattedEpisode = "{0}x{1:D2}" -f $season, $episode

        Write-Host "Extracted season: $season, episode: $episode, formatted: $formattedEpisode"

        # 遍历所有视频文件，查找匹配的文件
        foreach ($video in $videoFiles) {
            Write-Host "Checking video: '$($video.Name)'"

            # 提取文件名（不包含扩展名）
            $videoNameWithoutExtension = $video.BaseName

            if ($video.Name -match " - $formattedEpisode - ") {
                # 提取片名和本集名称
                if ($videoNameWithoutExtension -match "^(.*?) - $formattedEpisode - (.*?)$") {
                    $title = $matches[1]
                    $episodeName = $matches[2]

                    # 提取字幕文件的语言后缀，包括扩展名
                    $languageSuffix = $subtitle.Name -replace ".*?(\.[\w-]+(?:\.ass|\.srt))", '$1'


                    # 构建新的字幕文件名，保留原始扩展名
                    $newSubtitleName = "$title - $formattedEpisode - $episodeName$languageSuffix"
                    $newSubtitlePath = Join-Path -Path $subtitle.DirectoryName -ChildPath $newSubtitleName

                    # 重命名字幕文件
                    Rename-Item -Path $subtitle.FullName -NewName $newSubtitlePath
                    Write-Host "Renamed '$($subtitle.Name)' to '$newSubtitleName'"
                    break
                }
            } else {
                Write-Host "No match found in video: '$($video.Name)' for formatted episode: '$formattedEpisode'"
            }
        }
    } else {
        Write-Host "No season and episode found in subtitle: '$($subtitle.Name)'"
    }
}

Write-Host "Processing complete."