defmodule Exred.Node.GPIOIn do
  @moduledoc """
  Receives data from a GPIO pin.
  
  Uses [Elixir ALE](https://github.com/fhunleth/elixir_ale) to interface with GPIO.
  
  It can work in two modes:
  
  - 'monitor': monitors the pin and sends a message on pin interrupt
  - 'read\\_on\\_message': reads the pin state and sends the data when triggered by an incoming message

  **Incoming message format**  
  Anything
  
  **Outgoing message format**
  
  _read on message_ mode:
  
  ```elixir
  msg = %{
    payload :: 0 | 1
  }
  ```

  _monitor_ mode:

  ```elixir
  msg = %{
    payload :: %{
      pin_number :: integer,
      condition  :: :rising | :falling
    }
  }
  ```
  """

  @name "GPIO In"
  @category "input"
  @info @moduledoc
  @config %{
    name: %{
      info: "Visible node name",
      value: @name, 
      type: "string", 
      attrs: %{max: 20}
    },
    pin_number: %{
      info: "GPIO pin number that the node will read",
      value: 0, 
      type: "number", 
      attrs: %{min: 0}
    },
    mode: %{
      info: "read_on_message or monitor",
      type: "list-singleselect", 
      value: nil,
      attrs: %{items: ["read_on_message", "monitor"]}
    },
    monitored_transition: %{
      info: "send message in rising and/or falling edge",
      type: "list-multiselect",
      value: [],
      attrs: %{items: ["rising", "falling"]}
    }
  }
  @ui_attributes %{
    fire_button: true, 
    right_icon: "settings-input-component",
    config_order: [:name,:pin_number,:mode,:monitored_transition]
  }
  
  use Exred.Library.NodePrototype
  alias ElixirALE.GPIO
  require Logger
  
  
  @impl true
  def node_init(state) do
    # start GPIO process
    {:ok, pid} = GPIO.start_link(state.config.pin_number.value, :input)
    
    # set interrupt monitoring if in 'monitor' mode
    if state.mode.value == "monitor" do
      interrupt = case state.config.monitored_transition.value do
        [] -> :none
        ["rising"]  -> :rising
        ["falling"] -> :falling
        _ -> :both
      end
      GPIO.set_int(pid, interrupt)
    end

    state |> Map.put(:pid, pid)
  end

  @impl true
  def handle_msg(msg, state) do 
    case [state.config.mode.value, msg] do 

      ["read_on_message", _] -> 
        # pin state is 0 or 1
        pin_state = GPIO.read(state.pid)
        { %{msg | payload: pin_state}, state}
        
      ["monitor", {:gpio_interrupt, _pin, condition}] ->
        # condition can be :rising or :falling
        payload = %{pin: state.config.pin_number.value, condition: condition}
        { %{msg | payload: payload}, state}

      # catch all
      [mode, _] ->
        Logger.warn "unhandled message in #{mode} mode"
        {msg, state}

    end
  end

  
  @impl true
  def fire(state) do
    # send a message to self to trigger reading the pin
    send self, "fire"
    state
  end
end
