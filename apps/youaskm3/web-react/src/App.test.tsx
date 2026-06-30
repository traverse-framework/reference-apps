import { render, screen } from '@testing-library/react'
import App from './App'

describe('App', () => {
  it('renders the app title', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: /youaskm3/i })).toBeInTheDocument()
  })

  it('renders the run button', () => {
    render(<App />)
    expect(screen.getByRole('button', { name: /run/i })).toBeInTheDocument()
  })
})
