defmodule CutTheCrab.Video do
  @moduledoc """
  비디오 파일 처리를 위한 모듈입니다.
  """

  @doc """
  비디오 파일의 메타데이터를 추출합니다.

  ## 반환값
  ```
  {:ok, %{
    duration: "00:10:30",  # 영상 길이
    width: 1920,           # 가로 해상도
    height: 1080,          # 세로 해상도
    format: "mp4",         # 파일 형식
    codec: "h264",         # 비디오 코덱
    bitrate: "2000k"       # 비트레이트
  }}
  ```
  """
  def extract_metadata(file_path) do
    case System.cmd("ffprobe", [
      "-v", "quiet",
      "-print_format", "json",
      "-show_format",
      "-show_streams",
      file_path
    ]) do
      {output, 0} ->
        parse_metadata(output)
      {_, _} ->
        {:error, "Failed to extract metadata"}
    end
  end

  defp parse_metadata(json_output) do
    case Jason.decode(json_output) do
      {:ok, data} ->
        video_stream = Enum.find(data["streams"], &(&1["codec_type"] == "video"))
        format = data["format"]

        metadata = %{
          duration: format["duration"],
          width: video_stream["width"],
          height: video_stream["height"],
          format: format["format_name"],
          codec: video_stream["codec_name"],
          bitrate: format["bit_rate"]
        }

        {:ok, metadata}

      _ ->
        {:error, "Failed to parse metadata"}
    end
  end

  @doc """
  비디오 파일에서 썸네일을 추출합니다.
  """
  def generate_thumbnail(file_path, output_path, time \\ "00:00:01") do
    System.cmd("ffmpeg", [
      "-ss", time,
      "-i", file_path,
      "-vframes", "1",
      "-q:v", "2",
      output_path
    ])
    |> case do
      {_, 0} -> {:ok, output_path}
      _ -> {:error, "Failed to generate thumbnail"}
    end
  end
end
