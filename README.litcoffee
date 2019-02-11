
![PlayFrame](https://avatars3.githubusercontent.com/u/47147479)
# Component

###### 0.3 kB Pure Stateful Styled Components

## Installation
```sh
npm install --save @playframe/component
```

## Description
Pure Functional Styled Web Components for
[PlayFrame](https://github.com/playframe/playframe). Components are
rendered independetly from the rest of the app. By using
[Shadow DOM](https://developers.google.com/web/fundamentals/web-components/shadowdom)
provided by
[ShaDOM](https://github.com/playframe/shadom)
we achieve scoped styling and simple css selectors.
Please consider using
[CSS Variables](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_variables)
for maximum animation performance and flexibility


## Usage
```js
import oversync from '@playframe/oversync'
import component from '@playframe/component'

const sync = oversync(Date.now, requestAnimationFrame)
const Component = component(sync)

export default makeMyCounter = (Component)=>
  Component({
    seconds: 0
    _: {
      reset: ()=> seconds: 0
      increment: (x, state)=> {
        state.seconds++
        setTimeout(state._.increment, 1000 - Date.now() % 1000)
      }
    }
  })((state)=>
    <my-counter style={ {'--border': state.border} }>
      <style>{`
        :host {
          display: block;
          border: var(--border, 0);
        }
      `}</style>
      <div>
        {state.seconds} seconds passed
        <br>
        <button onclick={state._.reset}> Reset </button>
      </div>
    </my-counter>
  )

// our Counter instance
const MyCounter = makeMyCounter(Component)

// reset in 10 seconds
setTimeout(MyCounter._.reset, 10000)

const view = ()=>
  <MyCounter border="1px solid grey"></MyCounter>

```

## Annotated Source

We are going to use [statue](https://github.com/playframe/statue)
for managing state of our Component

    statue = require '@playframe/statue'

Let' export a higher order function that takes `sync` engine,
`state_actions` for statue and a pure `view` function

    module.exports = (sync)=>(state_actions)=>(view)=>
      _v_root = null
      _v_dom = null
      _props = null
      _scheduled = false

Creating a statue that will deliver the latest state on
`sync.finally` and will schedule render

      _state = statue state_actions, sync.finally, (state)=>
        unless state is _state
          _state = state
          unless _scheduled
            _scheduled = true
            sync.render render
        return


      render_with = (props)=>
        if props
          _state = _state._(_props = props)
        render()
        return

`render` is responsible for producing new virtual DOM and using `patch`
method for shadow DOM mutation provided by
[ShaDOM](https://github.com/playframe/shadom).
Please make noted that we are cleaning and keeping `_v_root` node
for fast equality pass when ShaDOM is mutating parent scrope of DOM.
This makes our components rerendered only if something changes in their
own state

      render = =>
        _scheduled = false

        new_v_dom = view _state

        unless _v_root # first run
          _v_root = new_v_dom
          attr = _v_root[1] or= {}
          attr.attachShadow or= mode: 'open'
          attr.key or= Math.random()
        else
          unless _v_dom # second run
            _v_dom = _v_root
          else # third run
            # freeing obsolete children
            _v_root.length = 2

          _v_root.patch new_v_dom, _v_dom
          _v_dom = new_v_dom

        return

Here we create our `Component` function that mimics your `view`
function. But first it's checking if `props` are meant to update
components inner `_state`.

      Component = (props)=>
        if _v_root
          unless props is _props
            # shallow equality check
            for k, v of props when v isnt _state[k]
              # updating state with props and rendering
              render_with props
              break

        else # first run
          # will create _v_root
          render_with props

        # always returning the same _v_root reference
        # this will skip rerender with the rest of the app
        _v_root

Assigning high level methods from statue and our fresh `Component` is
ready!

      Component._ = _state._


      Component
