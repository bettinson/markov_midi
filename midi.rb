require 'midilib'
require 'midilib/io/seqreader'
require 'midilib/sequence'
require 'midilib/consts'
require 'pp'

include MIDI

# Create a new, empty sequence.
seq = Sequence.new()

# Read the contents of a MIDI file into the sequence.
File.open('More Interesting Melody.mid', 'rb') { | file | seq.read(file) }

events = []

events = seq.map do |track|
  track.map { |e| e }
end

class Note
  attr_accessor :position, :note, :length

  def initialize(position, note, length)
    @position = position
    @note = note
    @length = length
  end
  
  def to_s
    "#{@position}, #{@note}, #{@length}"
  end
end

quarter_note_length = seq.note_to_delta('quarter')

notes = []

events.first.each do |event|
  if event.kind_of?(MIDI::NoteOn)
    note = Note.new(event.time_from_start, event.note, quarter_note_length)
    notes << note
  end
end

frequencies = Hash.new { |h, k| h[k] = [] }

notes.each_cons(2) do |w1, w2|
  frequencies[w1.note] << w2
end

# Make the last note loop back to the first 
frequencies[notes.last.note] << notes.first

generated = [notes.sample]

for i in 0..32 do 
  next_note = frequencies[generated.last.note].sample
  next_note.position = i * quarter_note_length
  generated << next_note
end

# Generate the midi 
seq = Sequence.new()

track = Track.new(seq)
seq.tracks << track
track.events << Tempo.new(Tempo.bpm_to_mpq(120))
track.events << MetaEvent.new(META_SEQ_NAME, 'Markov Type Beat')

# Create a track to hold the notes. Add it to the sequence.
track = Track.new(seq)
seq.tracks << track

# Add a volume controller event (optional).
track.events << Controller.new(0, CC_VOLUME, 127)

# Add events to the track: a major scale. Arguments for note on and note off
# constructors are channel, note, velocity, and delta_time. Channel numbers
# start at zero. We use the new Sequence#note_to_delta method to get the
# delta time length of a single quarter note.
track.events << ProgramChange.new(0, 1, 0)
quarter_note_length = seq.note_to_delta('quarter')

generated.each do |generated_note|
  track.events << NoteOn.new(0, generated_note.note, 127, 0)
  track.events << NoteOff.new(0, generated_note.note, 127, quarter_note_length) 
end

File.open('from_scratch.mid', 'wb') { |file| seq.write(file) }