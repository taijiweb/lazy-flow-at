{expect, iit, idescribe, nit, ndescribe} = require('bdd-test-helper')

{flow} = require './index'

describe 'lazy-flow-at', ->

  it 'should process flow.at', ->
    m = {}
    path1 = flow.at(m, 'x.y')
    expect(path1()).to.equal undefined
    called = false
    path1.onInvalidate -> called = true
    path1(1)
    expect(called).to.equal true
    expect(path1()).to.equal 1
    expect(m.x.y).to.equal 1
    called = false
    m.x = {}
    expect(called).to.equal true
    expect(m.x.y).to.equal undefined


  it 'should process flow.at without root', ->
    window.x = undefined
    path1 = flow.at('x.y')
    expect(path1()).to.equal undefined
    path1(1)
    expect(path1()).to.equal 1
    if typeof window != 'undefined'
      root = window
    else root = global
    expect(root.x.y).to.equal 1
