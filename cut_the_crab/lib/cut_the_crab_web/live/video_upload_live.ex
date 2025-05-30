defmodule CutTheCrabWeb.VideoUploadLive do
  use CutTheCrabWeb, :live_view
  alias CutTheCrab.Video

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:metadata, nil)
     |> assign(:thumbnail_path, nil)
     |> allow_upload(:video,
       accept: ~w(video/mp4 video/quicktime video/x-matroska video/x-msvideo),
       max_entries: 1,
       max_file_size: 5_000_000_000, # 5GB
       chunk_size: 64_000, # 64KB chunks
       progress: &handle_progress/3,
       auto_upload: true
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
        # 파일을 저장하고 메타데이터를 분석합니다
        dest = Path.join(["priv", "static", "uploads", entry.client_name])
        File.cp!(path, dest)

        case Video.extract_metadata(dest) do
          {:ok, metadata} ->
            # 썸네일 생성
            thumbnail_path = Path.join(["priv", "static", "uploads", "thumbnails", "#{Path.basename(entry.client_name, Path.extname(entry.client_name))}.jpg"])
            File.mkdir_p!(Path.dirname(thumbnail_path))
            Video.generate_thumbnail(dest, thumbnail_path)

            {:ok, %{path: dest, metadata: metadata, thumbnail_path: thumbnail_path}}
          {:error, _} ->
            {:ok, %{path: dest}}
        end
      end)

    metadata = case uploaded_files do
      [%{metadata: metadata}|_] -> metadata
      _ -> nil
    end

    thumbnail_path = case uploaded_files do
      [%{thumbnail_path: path}|_] -> Path.join(["/uploads", "thumbnails", Path.basename(path)])
      _ -> nil
    end

    {:noreply,
     socket
     |> update(:uploaded_files, &(&1 ++ uploaded_files))
     |> assign(:metadata, metadata)
     |> assign(:thumbnail_path, thumbnail_path)}
  end

  defp handle_progress(:video, entry, socket) do
    if entry.done? do
      {:noreply, socket}
    else
      # 업로드 진행 상황을 처리합니다
      {:noreply, socket}
    end
  end

  # 파일 크기를 사람이 읽기 쉬운 형태로 변환하는 함수
  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_000_000_000 -> "#{Float.round(bytes / 1_000_000_000, 1)}GB"
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)}MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)}KB"
      true -> "#{bytes}B"
    end
  end

  # 시간을 포맷팅하는 함수
  defp format_duration(duration) when is_binary(duration) do
    case Float.parse(duration) do
      {seconds, _} ->
        hours = floor(seconds / 3600)
        minutes = floor(rem(seconds, 3600) / 60)
        remaining_seconds = rem(floor(seconds), 60)
        :io_lib.format("~2..0B:~2..0B:~2..0B", [hours, minutes, remaining_seconds])
      _ ->
        "00:00:00"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        영상 업로드
        <:subtitle>업로드할 영상 파일을 선택해주세요.</:subtitle>
      </.header>

      <div class="mt-8">
        <form id="upload-form" phx-submit="save" phx-change="validate">
          <.live_file_input upload={@uploads.video} class="sr-only" />

          <div class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
            <div class="text-center">
              <svg class="mx-auto h-12 w-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z" clip-rule="evenodd" />
              </svg>
              <div class="mt-4 flex text-sm leading-6 text-gray-600">
                <label for={@uploads.video.ref} class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
                  <span>파일 업로드</span>
                </label>
                <p class="pl-1">또는 드래그 앤 드롭</p>
              </div>
              <p class="text-xs leading-5 text-gray-600">MP4, AVI, MOV, MKV (최대 5GB)</p>
            </div>
          </div>

          <%= for entry <- @uploads.video.entries do %>
            <div class="mt-4">
              <div class="flex items-center gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <span class="font-medium"><%= entry.client_name %></span>
                    <span class="text-zinc-500"><%= format_bytes(entry.client_size) %></span>
                  </div>
                  <div class="mt-2 overflow-hidden rounded-full bg-zinc-100">
                    <div class="h-2 bg-indigo-600" style={"width: #{entry.progress}%"}></div>
                  </div>
                </div>
                <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-zinc-500 hover:text-zinc-600">
                  취소
                </button>
              </div>

              <%= for err <- upload_errors(@uploads.video, entry) do %>
                <div class="mt-2 text-sm text-red-600">
                  <%= error_to_string(err) %>
                </div>
              <% end %>
            </div>
          <% end %>

          <%= if @metadata do %>
            <div class="mt-8 rounded-lg border border-gray-200 p-4">
              <h3 class="text-lg font-semibold">비디오 정보</h3>
              <%= if @thumbnail_path do %>
                <div class="mt-4">
                  <img src={@thumbnail_path} alt="Video thumbnail" class="rounded-lg" />
                </div>
              <% end %>
              <dl class="mt-4 grid grid-cols-2 gap-4">
                <div>
                  <dt class="text-sm font-medium text-gray-500">재생 시간</dt>
                  <dd class="text-sm text-gray-900"><%= format_duration(@metadata.duration) %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">해상도</dt>
                  <dd class="text-sm text-gray-900"><%= @metadata.width %>x<%= @metadata.height %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">코덱</dt>
                  <dd class="text-sm text-gray-900"><%= @metadata.codec %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">비트레이트</dt>
                  <dd class="text-sm text-gray-900"><%= format_bytes(String.to_integer(@metadata.bitrate)) %>/s</dd>
                </div>
              </dl>
            </div>
          <% end %>

          <%= if !Enum.empty?(@uploads.video.entries) do %>
            <div class="mt-6 flex items-center justify-end gap-x-6">
              <button type="submit" class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
                업로드
              </button>
            </div>
          <% end %>
        </form>
      </div>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "파일이 너무 큽니다"
  defp error_to_string(:too_many_files), do: "파일은 하나만 업로드할 수 있습니다"
  defp error_to_string(:not_accepted), do: "지원하지 않는 파일 형식입니다"
end
