import gradio as gr
import re
import os
from datetime import timedelta
import srt
import zipfile
import tempfile
from datetime import datetime

def parse_vtt_time(time_str):
    match = re.match(r"(?:(\d+):)?(\d{2}):(\d{2})\.(\d{3})", time_str)
    if not match:
        raise ValueError(f"Invalid time format: {time_str}")
    groups = match.groups()
    hours = int(groups[0] or 0)
    minutes = int(groups[1])
    seconds = int(groups[2])
    milliseconds = int(groups[3])
    return timedelta(hours=hours, minutes=minutes, seconds=seconds, milliseconds=milliseconds)

def format_vtt_time(delta):
    total_seconds = int(delta.total_seconds())
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    milliseconds = delta.microseconds // 1000
    return f"{hours}:{minutes:02}:{seconds:02}.{milliseconds:03}"

def split_vtt_segment(segment):
    text = segment['text'].strip()
    parts = text.split('。')
    split_segments = []
    start_time = segment['start']
    end_time = segment['end']
    total_duration = (end_time - start_time).total_seconds()
    total_chars = len(text)

    #print(f"Segment ID: {segment['id']}, Start: {start_time}, End: {end_time}, Text: {text}")

    current_start = start_time

    for i, part in enumerate(parts):
        if i < len(parts) - 1:
            part += '。'
        if part:
            part_duration = total_duration * len(part) / total_chars
            part_end = current_start + timedelta(seconds=part_duration)
            split_segments.append({
                'id': segment['id'],
                'start': current_start,
                'end': part_end,
                'text': part
            })
            current_start = part_end
            #print(f"  Split Part: {part}, Start: {current_start}, End: {part_end}")

    return split_segments

def parse_vtt_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    captions = []
    caption = {'id': None, 'start': None, 'end': None, 'text': ''}
    for line in lines:
        line = line.strip()
        if not line:
            if caption['start'] is not None:
                captions.append(caption)
                caption = {'id': None, 'start': None, 'end': None, 'text': ''}
        elif re.match(r"\d+", line) and caption['id'] is None:
            caption['id'] = line
        elif '-->' in line:
            times = line.split(' --> ')
            caption['start'] = parse_vtt_time(times[0])
            caption['end'] = parse_vtt_time(times[1])
        else:
            caption['text'] += (line + ' ')

    if caption['start'] is not None:
        captions.append(caption)

    return captions

def save_vtt_file(captions, file_path):
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('WEBVTT\n\n')
        for caption in captions:
            f.write(f"{caption['id']}\n")
            f.write(f"{format_vtt_time(caption['start'])} --> {format_vtt_time(caption['end'])}\n")
            f.write(f"{caption['text'].strip()}\n\n")

def split_vtt_captions(captions):
    split_captions = []
    for caption in captions:
        split_captions.extend(split_vtt_segment(caption))
    return split_captions

def split_srt_segment(segment):
    text = segment.content
    parts = text.split('。')
    split_segments = []
    start_time = segment.start
    end_time = segment.end
    total_duration = (end_time - start_time).total_seconds()
    total_chars = len(text)

    #print(f"Segment Index: {segment.index}, Start: {start_time}, End: {end_time}, Text: {text}")

    current_start = start_time

    for i, part in enumerate(parts):
        if i < len(parts) - 1:
            part += '。'
        if part:
            part_duration = total_duration * len(part) / total_chars
            part_end = current_start + timedelta(seconds=part_duration)
            split_segments.append(srt.Subtitle(index=segment.index, start=current_start, end=part_end, content=part))
            current_start = part_end
            #print(f"  Split Part: {part}, Start: {current_start}, End: {part_end}")

    return split_segments

def split_srt_file(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        subtitles = list(srt.parse(f.read()))

    new_subtitles = []
    for subtitle in subtitles:
        new_subtitles.extend(split_srt_segment(subtitle))


    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(srt.compose(new_subtitles))

def process_files(files):
    results = []

    timestamp_patch = datetime.now().strftime("%Y%m%d%H%M%S")
    temp_dir = os.path.join(tempfile.gettempdir(), f"tempdir_{timestamp_patch}")
    os.makedirs(temp_dir, exist_ok=True)

    for input_file in files:
        base_name = os.path.splitext(input_file)[0]
        base_name = base_name.replace("_ja","")
        if input_file.endswith('.vtt'):
            captions = parse_vtt_file(input_file)
            split_captions = split_vtt_captions(captions)
            output_file = f'{base_name}_splitted_ja.vtt'
            output_file = os.path.join(temp_dir,output_file)
            save_vtt_file(split_captions, output_file)
            results.append(output_file)

        elif input_file.endswith('.srt'):
            output_file = f'{base_name}_splitted_ja.srt'
            output_file= os.path.join(temp_dir,output_file)
            split_srt_file(input_file, output_file)
            results.append(output_file)
        else:
            print(f"Unsupported file format: {input_file}")

    # If there are multiple output files, zip them
    if len(results) > 1:
        zip_file = 'splitted_files.zip'
        zip_file = os.path.join(temp_dir,zip_file)
        with zipfile.ZipFile(zip_file, 'w') as zipf:
            for file in results:
                zipf.write(file, os.path.basename(file))
        results.append(zip_file)

    return results

def clear_files():
    return None, None

def process_and_display(files):
    if not files:
        return None
    results = process_files(files)
    return results

