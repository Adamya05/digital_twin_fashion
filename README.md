# digital_twin_fashion

Digital Twin Fashion App - Virtual try-on fashion platform.

## UP2You Project Summary & Replication Notes

### Overview
UP2You reconstructs a personalized texturable 3D avatar from a loose photo collection. The pipeline stitches diffusion-based novel view synthesis, segmentation, SMPL-X body fitting, and texture baking into a tuning-free workflow aimed at quick turnarounds (approximately 90 minutes on mid-range GPUs).

### Repository Layout (high level)
- `assets/`: figures for the paper and teaser GIF.
- `core/`, `up2you/`: Python sources implementing diffusion guidance, geometry fitting, and rendering utilities.
- `human_models/`, `pretrained_models/`: large checkpoints pulled from Hugging Face (not versioned in Git).
- `examples/`: sample unconstrained photos you can feed into the pipeline.
- `outputs/`: target directory for generated meshes, renders, and logs.
- `scripts/` (`run.sh`, `run_inference.bat`, `inference.py`, `inference_low_gpu.py`): orchestration entry points for Linux/macOS and Windows, plus a reduced-memory inference path.

### How to Replicate the Results
1. Clone the repo and enter it:
   ```bash
   git clone https://github.com/zcai0612/UP2You.git && cd UP2You
   ```
2. Create and activate the Conda environment (Python 3.10):
   ```bash
   conda create -n up2you python=3.10
   conda activate up2you
   ```
3. Install core dependencies:
   ```bash
   pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu118
   pip install kaolin==0.17.0 -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.4.1_cu118.html
   pip install -r requirements.txt
   conda install -y libffi==3.3
   ```
4. Add PyTorch3D with CUDA support (example for Linux):
   ```bash
   wget https://anaconda.org/pytorch3d/pytorch3d/0.7.8/download/linux-64/pytorch3d-0.7.8-py310_cu118_pyt241.tar.bz2
   conda install pytorch3d-0.7.8-py310_cu118_pyt241.tar.bz2
   ```
   Windows users need to build/install a CUDA-enabled wheel manually; the provided `build_pytorch3d.bat` script helps.

5. Download required weights and body templates from Hugging Face:
   ```bash
   export HF_ENDPOINT="https://hf-mirror.com"  # optional mirror
   hf download Co2y/UP2You --local-dir ./src
   mv ./src/human_models ./
   mv ./src/pretrained_models ./
   rm -rf ./src
   ```
6. Prepare your own photo set:
   - Place 10–30 diverse images of the target person (mixed poses, clothing, lighting) in a folder under `examples/` (or point `--data_dir` to any directory).
   - Ensure faces and full bodies stay visible; remove duplicates for faster runs.

7. Run inference (choose one):
   ```bash
   python inference_low_gpu.py --base_model_path stabilityai/stable-diffusion-2-1-base --segment_model_name ZhengPeng7/BiRefNet --data_dir examples --output_dir outputs
   bash run.sh  # Linux/macOS convenience wrapper
   run_inference.bat  # Windows batch script; accepts flags such as --only_body
   ```

8. Inspect `outputs/` for meshes, baked textures, rendered turntables, and log files. Intermediate checkpoints land under `outputs/<run_id>/`.

### Operational Notes
- Keep CUDA 11.8 toolkits on the machine; `nvdiffrast` and custom CUDA ops rebuild against it.
- GPUs with 4 GB VRAM must use `inference_low_gpu.py` or `run_inference.bat --only_body` to avoid OOM; expect longer runtimes.
- PyTorch3D wheels from PyPI are CPU-only on Windows; recompile for GPU acceleration if you need faster rasterization.
- Local scripts such as `render_shirt_front.py` illustrate how to re-render clothing-only meshes once the main pipeline finishes.
- For repeatability, document the photo subset, command flags, and git commit you used when sharing results.

## Backend API for Orchestrating UP2You

A lightweight FastAPI backend is included under `backend/` to remotely launch UP2You inference runs and monitor their progress. The service wraps the existing pipeline scripts so collaborators can trigger avatar reconstructions without direct shell access to the GPU host.

### 1. Install backend dependencies
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r backend/requirements.txt
```

### 2. Configure runtime paths
Set the following environment variables to point the API at your local UP2You checkout (defaults are shown in parentheses):

| Variable | Description |
| --- | --- |
| `UP2YOU_REPO_PATH` (`/opt/UP2You`) | Absolute path to the UP2You repository on disk. |
| `PYTHON_EXECUTABLE` (`python`) | Python interpreter used to run the inference scripts. |
| `UP2YOU_INFERENCE_SCRIPT` (`inference_low_gpu.py`) | Default script invoked for new jobs. |
| `UP2YOU_BASE_MODEL_PATH` (`stabilityai/stable-diffusion-2-1-base`) | Default diffusion model identifier. |
| `UP2YOU_SEGMENT_MODEL_NAME` (`ZhengPeng7/BiRefNet`) | Default segmentation checkpoint. |

### 3. Run the API locally
```bash
uvicorn backend.main:app --reload
```
The service exposes the following endpoints under `http://localhost:8000/api`:

- `POST /api/jobs`: queue a new reconstruction job. Supply JSON payload:
  ```json
  {
    "data_dir": "examples/my_friend",
    "output_dir": "outputs/my_friend",
    "extra_args": ["--only_body"]
  }
  ```
- `GET /api/jobs/{job_id}`: poll job status and retrieve the log file path once complete.
- `GET /health`: simple readiness probe.

Jobs execute asynchronously in background threads. Output logs stream to `<output_dir>/<job_id>.log`, and the API reports success or failure once the underlying UP2You script exits.

### 4. Integrating with a frontend
The job endpoint returns a `job_id` that can be stored client-side and used to periodically check progress. Once a job succeeds, the frontend can surface assets from the configured `output_dir` (meshes, renders, textures) or trigger additional processing steps.

> **Tip:** wrap this backend with authentication and rate-limiting before exposing it on a shared GPU host.
