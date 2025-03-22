defmodule ArenaWeb.Home.HomeLive do
  use ArenaWeb, :live_view
  alias ArenaWeb.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen w-screen flex items-center justify-center antialiased">
      <div class="flex flex-col items-center w-1/2">
        <div class="mb-6 text-gray-600 text-lg">
          <h1>Press and hold</h1>
        </div>

        <button
          type="button"
          id="microphone"
          phx-hook="Microphone"
          data-endianness={System.endianness()}
          class="p-5 text-white bg-blue-700 rounded-full text-sm hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 active:bg-red-400 group"
        >
          <Components.Icons.microphone class="w-8 h-8 group-active:animate-pulse" />
        </button>

        <form phx-change="noop" phx-submit="noop" class="hidden">
          <.live_file_input upload={@uploads.audio} />
        </form>

        <div class="mt-6 flex space-x-1.5 items-center text-gray-600 text-lg">
          <div>Transcription:</div>
          <.async_result :let={transcription} :if={@transcription} assign={@transcription}>
            <:loading>
              <Components.Utils.spinner />
            </:loading>
            <:failed :let={_reason}>
              <span>Oops, something went wrong!</span>
            </:failed>
            <span class="text-gray-900 font-medium">{transcription}</span>
          </.async_result>
        </div>
      </div>
    </div>

    <script>
      const SAMPLING_RATE = 16_000;

      window.hooks.Microphone = {
        mounted() {
          this.mediaRecorder = null;

          this.el.addEventListener("mousedown", (event) => {
            this.startRecording();
          });

          this.el.addEventListener("mouseup", (event) => {
            this.stopRecording();
          });
        },

        startRecording() {
          this.audioChunks = [];

          navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
            this.mediaRecorder = new MediaRecorder(stream);

            this.mediaRecorder.addEventListener("dataavailable", (event) => {
              if (event.data.size > 0) {
                this.audioChunks.push(event.data);
              }
            });

            this.mediaRecorder.start();
          });
        },

        stopRecording() {
          this.mediaRecorder.addEventListener("stop", (event) => {
            if (this.audioChunks.length === 0) return;

            const audioBlob = new Blob(this.audioChunks);

            audioBlob.arrayBuffer().then((buffer) => {
              const context = new AudioContext({ sampleRate: SAMPLING_RATE });

              context.decodeAudioData(buffer, (audioBuffer) => {
                const pcmBuffer = this.audioBufferToPcm(audioBuffer);
                const buffer = this.convertEndianness32(
                  pcmBuffer,
                  this.getEndianness(),
                  this.el.dataset.endianness
                );
                this.upload("audio", [new Blob([buffer])]);
              });
            });
          });

          this.mediaRecorder.stop();
        },

        isRecording() {
          return this.mediaRecorder && this.mediaRecorder.state === "recording";
        },

        audioBufferToPcm(audioBuffer) {
          const numChannels = audioBuffer.numberOfChannels;
          const length = audioBuffer.length;

          const size = Float32Array.BYTES_PER_ELEMENT * length;
          const buffer = new ArrayBuffer(size);

          const pcmArray = new Float32Array(buffer);

          const channelDataBuffers = Array.from(
            { length: numChannels },
            (x, channel) => audioBuffer.getChannelData(channel)
          );

          // Average all channels upfront, so the PCM is always mono

          for (let i = 0; i < pcmArray.length; i++) {
            let sum = 0;

            for (let channel = 0; channel < numChannels; channel++) {
              sum += channelDataBuffers[channel][i];
            }

            pcmArray[i] = sum / numChannels;
          }

          return buffer;
        },

        convertEndianness32(buffer, from, to) {
          if (from === to) {
            return buffer;
          }

          // If the endianness differs, we swap bytes accordingly
          for (let i = 0; i < buffer.byteLength / 4; i++) {
            const b1 = buffer[i];
            const b2 = buffer[i + 1];
            const b3 = buffer[i + 2];
            const b4 = buffer[i + 3];
            buffer[i] = b4;
            buffer[i + 1] = b3;
            buffer[i + 2] = b2;
            buffer[i + 3] = b1;
          }

          return buffer;
        },

        getEndianness() {
          const buffer = new ArrayBuffer(2);
          const int16Array = new Uint16Array(buffer);
          const int8Array = new Uint8Array(buffer);

          int16Array[0] = 1;

          if (int8Array[0] === 1) {
            return "little";
          } else {
            return "big";
          }
        },
      };
    </script>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(transcription: nil)
      |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)

    {:ok, socket}
  end

  def handle_progress(:audio, entry, socket) do
    IO.inspect(entry, label: "Audio entry")
    {:noreply, socket}
  end

  def handle_progress(_name, _entry, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("noop", %{}, socket) do
    # We need phx-change and phx-submit on the form for live uploads,
    # but we make predictions immediately using :progress, so we just
    # ignore this event
    {:noreply, socket}
  end
end
