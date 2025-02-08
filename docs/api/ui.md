---
previous: false
next: false
---

# ui

Package available through wally under `alicesaidhi/conch-ui` or on pesde as `alicesaidhi/conch_ui`.

## Functions

### bind_to()

Binds the activation of Conch to a given user input or keycode.
This automatically mounts the UI if it has not yet been mounted.

- **Type**

	```luau
	function ui.bind_to(input: Enum.KeyCode | Enum.UserInputType)
	```

### mount()

Mounts the UI to the PlayerGui.

- **Type**

	```luau
	function ui.mount()
	```


### opened()

A vide source that stores if the UI is enbaled or not. When called with a boolean, sets it to that boolean. Otherwise, returns the currently stored boolean.

- **Type**

	```luau
	function ui.opened(new: boolean): boolean
	function ui.opened(): boolean
	```

### app()

Refers to the UI component for the Conch UI.

- **Type**

	```luau
	function ui.app()
	```
