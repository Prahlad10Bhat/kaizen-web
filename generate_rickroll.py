import wave
import struct
import math
import os

# Create audio directory if not exists
os.makedirs('d:/Apps/FlutterApps/kaizen/assets/audio', exist_ok=True)

SAMPLE_RATE = 44100
AMPLITUDE = 16000

def get_freq(note):
    notes = {
        'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.00, 'A4': 440.00, 'Bb4': 466.16, 'B4': 493.88, 'C5': 523.25,
        'D5': 587.33, 'E5': 659.25, 'F5': 698.46, 'G5': 783.99, 'A5': 880.00, 'Bb5': 932.33, 'B5': 987.77, 'C6': 1046.50
    }
    return notes.get(note, 0)

def generate_tone(note, duration_beats, tempo=113):
    freq = get_freq(note)
    beat_duration = 60.0 / tempo
    duration_secs = duration_beats * beat_duration
    num_samples = int(SAMPLE_RATE * duration_secs)
    samples = []
    
    for i in range(num_samples):
        # ADSR envelope
        attack = int(0.05 * SAMPLE_RATE)
        decay = int(0.1 * SAMPLE_RATE)
        release = int(0.1 * SAMPLE_RATE)
        sustain_level = 0.7
        
        envelope = 1.0
        if i < attack:
            envelope = i / attack
        elif i < attack + decay:
            envelope = 1.0 - (1.0 - sustain_level) * ((i - attack) / decay)
        elif i > num_samples - release:
            envelope = sustain_level * (num_samples - i) / release
        else:
            envelope = sustain_level
            
        t = float(i) / SAMPLE_RATE
        if freq > 0:
            # Add some harmonics for 8-bit style sound (square/triangle mix)
            val1 = math.sin(2.0 * math.pi * freq * t)
            val2 = 0.3 * math.sin(2.0 * math.pi * freq * 2 * t)
            val3 = 0.1 * math.sin(2.0 * math.pi * freq * 3 * t)
            value = int(AMPLITUDE * envelope * (val1 + val2 + val3))
        else:
            value = 0
        samples.append(value)
    return samples

melody = [
    # Never (C4, D4) gonna (F4, D4) give (A4) you (A4) up (G4)
    ('C4', 0.25), ('D4', 0.25), ('F4', 0.25), ('D4', 0.25), ('A4', 0.75), ('A4', 0.75), ('G4', 1.5), ('0', 0.5),
    # Never (C4, D4) gonna (F4, D4) let (G4) you (G4) down (F4, E4, D4)
    ('C4', 0.25), ('D4', 0.25), ('F4', 0.25), ('D4', 0.25), ('G4', 0.75), ('G4', 0.75), ('F4', 0.5), ('E4', 0.5), ('D4', 1.0), ('0', 0.5),
    # Never (C4, D4) gonna (F4, D4) run (F4) around (G4) and (E4) desert (D4) you (C4)
    ('C4', 0.25), ('D4', 0.25), ('F4', 0.25), ('D4', 0.25), ('F4', 0.75), ('G4', 0.5), ('E4', 0.75), ('D4', 0.5), ('C4', 1.0), ('0', 0.5),
    # Ooh (C4) give (G4) you up (F4)
    ('C4', 0.5), ('0', 0.25), ('G4', 0.75), ('F4', 2.0)
]

all_samples = []
for note, duration in melody:
    all_samples.extend(generate_tone(note, duration))

# Repeat chorus twice to make it around 18 seconds
all_samples = all_samples * 2

with wave.open('d:/Apps/FlutterApps/kaizen/assets/audio/rickroll.wav', 'w') as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(SAMPLE_RATE)
    # Pack data
    packed_data = bytearray(len(all_samples) * 2)
    for i, sample in enumerate(all_samples):
        # Clip to short limit
        sample = max(-32768, min(32767, sample))
        struct.pack_into('<h', packed_data, i * 2, sample)
    wav_file.writeframes(packed_data)
print("Created rickroll.wav")
