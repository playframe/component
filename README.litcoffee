
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
for maximum animation performance and flexibility.

You can create instances manually and keep them in parent state or
you can register them with `fp.use` or `h.use` and create them dynamically.
To be able to identify the same dynamic component we use a unique
object `mkey` as a
[WeakMap](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap)
key. For a `UserView` Component actual `user` object would be a perfect
WeakMap key

## Usage
```js
import h from '@playframe/h'
import oversync from '@playframe/oversync'
import component from '@playframe/component'

const sync = oversync(Date.now, requestAnimationFrame)
const Component = component(sync)

export default myCounter = (Component)=>
  Component({
    seconds: 0,
    _: {
      reset: ()=> {seconds: 0}
      increment: (x, state)=> {
        state.seconds++
        setTimeout( state._.increment,
          (1000 - Date.now() % 1000) || 1000 )
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
        {props.children}
        <br/>
        {state.seconds} seconds passed
        <br/>
        <button onclick={state._.reset}> Reset </button>
      </div>
    </my-counter>
  )

// our Counter instance with initial props
const MyCounter = myCounter(Component)({seconds: 42})

// reset in 10 seconds
setTimeout(MyCounter._.reset, 10000)

const view = ()=>
  <MyCounter border="1px solid grey">
    <h1>Hello</h1>
  </MyCounter>

// or we can register component as custom element
h.use({'my-counter': (props)=>
  let mkey = props && props.mkey
  makeMyCounter(Component)({mkey})(props)
})

// mkey is used as WeakMap key to cache our statefull component
const mkey = {uniqueObject: true}

const view = ()=>
  <my-counter mkey={mkey} border="1px solid grey">Hello</my-counter>

```

## Annotated Source

We are going to use [statue](https://github.com/playframe/statue)
for managing state of our Component

    evolve = require '@playframe/evolve'
    statue = require '@playframe/statue'

How about using a tree of
[WeakMap](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap)
instances to cache our Component instances by `mkey`?
This allows us to cache our components aggresively because our `_cache`
will be cleaned automatically by Garbage Collector if `mkey` gets dereferenced

Let's export a higher order function that takes `sync` engine,
`state_actions` for statue and a pure `view` function.

    module.exports = (sync)=>(state_actions)=>(view)=> _cache = new WeakMap; (upgrade)=>
      if (mkey = upgrade and upgrade.mkey) and
          Component = _cache.get mkey
        return Component

      _v_dom = null
      _props = null
      _rendering = false
      _state = evolve state_actions, upgrade

Creating a statue that will deliver the latest state on
`sync.render` and patch shadow DOM if needed

      _state = statue _state, sync.render, (state)=>
        _state = state
        do patch_shadow unless _rendering
        _rendering = false
        return

`patch_shadow` is responsible for producing new virtual DOM and using
`patch` method for shadow DOM mutation provided by
[ShaDOM](https://github.com/playframe/shadom).

      patch_shadow = =>
        {patch} = _v_dom
        _v_dom = view _state
        _v_dom.patch = patch
        patch _v_dom
        return

      render = =>
        _v_dom = view _state
        attr = _v_dom[1] or= {}
        attr.attachShadow or= mode: 'open'
        return

Here we create our `Component` function that mimics your `view`
function. But first it's checking if `props` are meant to update `_state`

      Component = (props)=>
        if _v_dom
          unless props is _props
            # shallow equality check
            for k, v of props when v isnt _state[k]
              # updating state with props and rendering
              _state = _state._ _props = props
              _rendering = true
              do render
              break

        else # first run
          _state = Object.assign _state._(), _props = props
          do render

        _v_dom

Assigning high level methods from statue, adding instance to cache and our
fresh `Component` is ready!

      Component._ = _state._

      _cache.set mkey, Component if mkey

      Component
