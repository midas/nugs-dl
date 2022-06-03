defmodule NugsDl.Track do

  defstruct ~w(
    id
    title
    set_num
    track_num
    disc_num
    stream_url
  )a

  def new(%{
      "trackID" => id,
      "songTitle" => title,
      "setNum" => set_num,
      "trackNum" => track_num,
      "discNum" => disc_num,
    })
  do
    %__MODULE__{
      id: id,
      title: String.trim(title),
      set_num: set_num,
      track_num: track_num,
      disc_num: disc_num,
    }
  end

end
