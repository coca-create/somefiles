
import os
import sys
import gradio as gr
from gradio_components import gr_components as gc
import warnings

warnings.filterwarnings("ignore", category=FutureWarning)
#print("Current working directory:", os.getcwd())
# 必要なら作業ディレクトリをスクリプトのディレクトリに変更
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

def get_base_path():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    else:
        return os.path.dirname(os.path.abspath(__file__))

base_path = get_base_path()

current_directory = os.getcwd()
#print(f"Current directory: {current_directory}")
cuda_path = os.path.join(base_path,"cuda")
cudnn_path = os.path.join(base_path, "cuda")
ffmpeg_path = os.path.join(base_path,"bin")
ffprobe_path = os.path.join(base_path,"bin")
#python_path = os.path.join(base_path, "python311")

os.environ["FFMPEG_PATH"] = ffmpeg_path
os.environ["FFPROBE_PATH"] = ffprobe_path
#os.environ["PYTHON_PATH"] = python_path
os.environ["CUDA_PATH"] = cuda_path
os.environ["CUDNN_PATH"] = cudnn_path

os.environ["PATH"] = cuda_path + ";" + cudnn_path + ";" + ffmpeg_path + ";" + ffprobe_path + ";" + os.environ["PATH"]
css="""

    .my-table-container {
        font-family:inherit !important;
        max-height: 400px;
        overflow-y: auto;
        border: 0.5px solid gray !important;
        padding: 10px;
        width:100%;
        margin:auto;
    }
    .my-table-wrapper {
        display: flex;
        justify-content: center;
    }
    .table {
        width: 100%;
        font-family:inherit;
        border:0.5px solid gray;
    }
    .dataframe{
        width:100%;
    }

    table { width: 100%; }
    
    
    """
with gr.Blocks(css=css) as UI:
    gc.gr_components()
UI.launch(debug=True,inbrowser=True)