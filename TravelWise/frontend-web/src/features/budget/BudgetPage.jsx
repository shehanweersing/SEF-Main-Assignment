import { Pencil, Plus, Trash2, Wallet } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { budgetApi, getOrCreateBudget } from '../../api/travelWiseApi'
import { tripApi } from '../../api/travelWiseApi'
import BudgetHealthCard from './BudgetHealthCard'
import { useAuth } from '../../context/AuthContext'

const expenseSchema = z.object({
  category: z.string().min(1, 'Choose a category'),
  description: z.string().min(2, 'Add a short description'),
  amount: z.coerce.number().positive('Amount must be greater than 0'),
  expenseDate: z.string().min(1, 'Select a date'),
})

const errorText = (error, fallback) => {
  const data = error.response?.data
  if (typeof data === 'string') return data
  if (data?.detail || data?.message) return data.detail || data.message
  if (data?.errors) return Object.values(data.errors).flat().join(' ')
  return error.message || fallback
}

const normalizeExpense = (expense) => ({
  ...expense,
  date: expense.expenseDate?.slice(0, 10),
  displayAmount: Number(expense.amount).toFixed(2),
})

export default function BudgetPage() {
  const { user } = useAuth()
  const [trips, setTrips] = useState([])
  const [trip, setTrip] = useState(null)
  const [budget, setBudget] = useState(null)
  const [categories, setCategories] = useState([])
  const [rows, setRows] = useState([])
  const [total, setTotal] = useState(0)
  const [filter, setFilter] = useState('')
  const [page, setPage] = useState(1)
  const [showExpenseForm, setShowExpenseForm] = useState(false)
  const [serverError, setServerError] = useState('')
  const [modal, setModal] = useState(null)
  const [modalItem, setModalItem] = useState(null)
  const [modalValues, setModalValues] = useState({})
  const [modalError, setModalError] = useState('')
  const [modalBusy, setModalBusy] = useState(false)
  const pageSize = 10
  const { register, handleSubmit, reset, formState: { errors } } = useForm({
    resolver: zodResolver(expenseSchema),
    defaultValues: { expenseDate: new Date().toISOString().slice(0, 10) },
  })

  async function loadExpenses(currentBudget = budget, currentPage = page, currentFilter = filter) {
    if (!currentBudget) return
    const { data } = await budgetApi.listExpenses(currentBudget.id, {
      category: currentFilter || undefined,
      page: currentPage,
      pageSize,
    })
    const items = Array.isArray(data) ? data : data.items
    setRows(items.map(normalizeExpense))
    setTotal(Array.isArray(data) ? items.length : data.total)
  }

  async function loadBudget(currentTrip) {
    const currentBudget = await getOrCreateBudget(currentTrip.id)
    setBudget(currentBudget)
    const { data } = await budgetApi.listCategories(currentBudget.id)
    setCategories(data)
    await loadExpenses(currentBudget, 1, '')
  }

  useEffect(() => {
    if (!user?.id) return
    tripApi.list(user.id).then(async ({ data }) => {
      const availableTrips = Array.isArray(data) ? data : data ? [data] : []
      setTrips(availableTrips)
      if (!availableTrips.length) {
        setTrip(null)
        setBudget(null)
        return
      }
      const currentTrip = availableTrips[0]
      setTrip(currentTrip)
      await loadBudget(currentTrip)
    }).catch((error) => setServerError(errorText(error, 'Could not load your trips.')))
  }, [user?.id])

  async function selectTrip(tripId) {
    const selectedTrip = trips.find((item) => String(item.id) === String(tripId))
    if (!selectedTrip || selectedTrip.id === trip?.id) return
    setServerError('')
    setTrip(selectedTrip)
    setBudget(null)
    setCategories([])
    setRows([])
    setTotal(0)
    setPage(1)
    setFilter('')
    setShowExpenseForm(false)
    try {
      await loadBudget(selectedTrip)
    } catch (error) {
      setServerError(errorText(error, 'Could not load the selected trip budget.'))
    }
  }

  useEffect(() => {
    if (budget) loadExpenses(budget, page, filter).catch((error) => setServerError(errorText(error, 'Could not load expenses.')))
  }, [budget, page, filter])

  async function submitExpense(values) {
    setServerError('')
    try {
      await budgetApi.addExpense({ ...values, budgetId: budget.id, amount: Number(values.amount) })
      reset({ expenseDate: new Date().toISOString().slice(0, 10) })
      setShowExpenseForm(false)
      setPage(1)
      await loadExpenses(budget, 1, filter)
    } catch (error) {
      setServerError(errorText(error, 'Could not save this expense.'))
    }
  }

  function openModal(type, item = null) {
    setModal(type)
    setModalItem(item)
    setModalError('')
    if (type === 'budget') setModalValues({ amount: budget?.totalAllocation || '' })
    if (type === 'create-budget') setModalValues({ amount: '' })
    if (type === 'expense') setModalValues({ category: item.category, description: item.description, amount: item.displayAmount, expenseDate: item.date })
    if (type === 'category') setModalValues({ name: item.name, allocatedAmount: item.allocatedAmount })
    if (type === 'new-category') setModalValues({ name: '', allocatedAmount: '' })
  }

  function closeModal() {
    if (!modalBusy) setModal(null)
  }

  async function submitModal(event) {
    event.preventDefault()
    setModalError('')
    setModalBusy(true)
    try {
      const amount = Number(modalValues.amount || modalValues.allocatedAmount)
      if (!Number.isFinite(amount) || amount <= 0) throw new Error('Enter an amount greater than zero.')
      if (modal === 'budget') {
        const { data } = await budgetApi.updateBudget(budget.id, { tripId: budget.tripId, totalAllocation: amount, currency: budget.currency })
        setBudget(data)
      } else if (modal === 'create-budget') {
        const currency = String(trip.currency || 'USD').trim().toUpperCase() || 'USD'
        const { data } = await budgetApi.createTripBudget(trip.id, { totalAllocation: amount, currency })
        setBudget(data)
        setCategories([])
        setRows([])
        setTotal(0)
      } else if (modal === 'expense') {
        if (!modalValues.category || !modalValues.description || !modalValues.expenseDate) throw new Error('Complete all expense fields.')
        await budgetApi.updateExpense(modalItem.id, { budgetId: budget.id, category: modalValues.category.trim(), description: modalValues.description.trim(), amount, expenseDate: modalValues.expenseDate })
        await loadExpenses(budget, page, filter)
      } else if (modal === 'new-category') {
        if (!modalValues.name?.trim()) throw new Error('Enter a category name.')
        const { data } = await budgetApi.addCategory(budget.id, { name: modalValues.name.trim(), allocatedAmount: amount })
        setCategories((current) => [...current, data].sort((a, b) => a.name.localeCompare(b.name)))
      } else if (modal === 'category') {
        if (!modalValues.name?.trim()) throw new Error('Enter a category name.')
        const { data } = await budgetApi.updateCategory(budget.id, modalItem.id, { name: modalValues.name.trim(), allocatedAmount: amount })
        setCategories((current) => current.map((item) => item.id === modalItem.id ? data : item).sort((a, b) => a.name.localeCompare(b.name)))
      }
      setModal(null)
    } catch (error) {
      setModalError(errorText(error, 'Could not save your changes.'))
    } finally {
      setModalBusy(false)
    }
  }

  async function deleteBudget() {
    if (!window.confirm('Delete this budget and all of its expenses?')) return
    try {
      await budgetApi.deleteBudget(budget.id)
      setBudget(null)
      setCategories([])
      setRows([])
      setTotal(0)
    } catch (error) {
      setServerError(errorText(error, 'Could not delete the budget.'))
    }
  }

  async function editExpense(row) {
    openModal('expense', row)
  }

  async function removeExpense(row) {
    if (!window.confirm('Delete this expense?')) return
    try {
      await budgetApi.deleteExpense(row.id)
      const nextPage = page > 1 && rows.length === 1 ? page - 1 : page
      setPage(nextPage)
      await loadExpenses(budget, nextPage, filter)
    } catch (error) {
      setServerError(errorText(error, 'Could not delete this expense.'))
    }
  }

  async function addCategory() {
    openModal('new-category')
  }

  async function editCategory(category) {
    openModal('category', category)
  }

  async function removeCategory(category) {
    if (!window.confirm(`Delete the ${category.name} category allocation?`)) return
    try {
      await budgetApi.deleteCategory(budget.id, category.id)
      setCategories((current) => current.filter((item) => item.id !== category.id))
    } catch (error) {
      setServerError(errorText(error, 'Could not delete this category.'))
    }
  }

  const currency = budget?.currency || trip?.currency || 'USD'
  const spent = rows.reduce((sum, row) => sum + Number(row.amount), 0)
  const totalPages = Math.max(1, Math.ceil(total / pageSize))

  return <>
    <div className="page-intro">
      <div><span className="eyebrow">Trip finances</span><h1>Budget, beautifully clear.</h1><p>Keep the numbers in view without letting them take over.</p></div>
      <span className="budget-trip-selector">
        <label htmlFor="budget-trip">Trip</label>
        <select id="budget-trip" value={trip?.id || ''} onChange={(event) => selectTrip(event.target.value)} disabled={!trips.length}>
          {!trips.length && <option value="">No trips found</option>}
          {trips.map((item) => <option key={item.id} value={item.id}>{item.destination} · {item.startDate?.slice(0, 10)}</option>)}
        </select>
      </span>
      <span>
        {budget && <button className="button button-light" onClick={() => openModal('budget')}><Pencil size={14} /> Edit allocation</button>}
        {budget && <button className="button button-light" onClick={deleteBudget}><Trash2 size={14} /> Delete budget</button>}
        {budget && <button className="button button-coral" onClick={() => setShowExpenseForm(!showExpenseForm)}><Plus size={16} /> Add expense</button>}
        {!budget && <button className="button button-coral" onClick={() => openModal('create-budget')}><Plus size={16} /> Create budget</button>}
      </span>
    </div>
    {!trips.length && <div className="form-error">Create a trip on the Trips page before adding a budget or expenses.</div>}
    {trip && budget && <BudgetHealthCard tripId={trip.id} currency={currency} />}
    <div className="feature-summary">
      <div className="summary-icon"><Wallet size={20} /></div>
      <div><span>Total allocated</span><strong>{currency} {Number(budget?.totalAllocation || 0).toFixed(2)}</strong></div>
      <div><span>Current page spend</span><strong>{currency} {spent.toFixed(2)}</strong></div>
      <div><span>Remaining</span><strong className="positive">{currency} {Math.max(0, Number(budget?.totalAllocation || 0) - spent).toFixed(2)}</strong></div>
    </div>
    {serverError && <div className="form-error">{String(serverError)}</div>}
    {budget && <section className="table-panel">
      <div className="table-heading"><h2>Category allocations</h2><button className="button button-light" onClick={addCategory}><Plus size={14} /> Add category</button></div>
      {categories.length ? categories.map((category) => <div className="table-row" key={category.id}>
        <span>{category.name}</span><strong>{currency} {Number(category.allocatedAmount).toFixed(2)}</strong>
        <span className="row-actions"><button className="icon-button" title="Edit category" onClick={() => editCategory(category)}><Pencil size={14} /></button><button className="icon-button" title="Delete category" onClick={() => removeCategory(category)}><Trash2 size={14} /></button></span>
      </div>) : <p>No category allocations configured.</p>}
    </section>}
    {showExpenseForm && <form className="inline-form" onSubmit={handleSubmit(submitExpense)}>
      <label>Category<select {...register('category')}><option value="">Select</option>{categories.map((category) => <option key={category.id}>{category.name}</option>)}{!categories.length && <><option>Stay</option><option>Transport</option><option>Experience</option><option>Food</option></>}</select>{errors.category && <small className="field-error">{errors.category.message}</small>}</label>
      <label>Description<input {...register('description')} placeholder="What was this for?" />{errors.description && <small className="field-error">{errors.description.message}</small>}</label>
      <label>Amount<input type="number" step="0.01" {...register('amount')} placeholder="0.00" />{errors.amount && <small className="field-error">{errors.amount.message}</small>}</label>
      <label>Date<input type="date" {...register('expenseDate')} />{errors.expenseDate && <small className="field-error">{errors.expenseDate.message}</small>}</label>
      <button className="button button-dark" type="submit">Save</button>
    </form>}
    <section className="table-panel">
      <div className="table-heading"><h2>Recent expenses</h2><span>{total} items</span></div>
      <label>Filter by category <input value={filter} onChange={(event) => { setFilter(event.target.value); setPage(1) }} placeholder="All categories" /></label>
      <div className="data-table"><div className="table-row table-header"><span>Category</span><span>Description</span><span>Date</span><span>Amount</span><span /></div>
        {rows.map((row) => <div className="table-row" key={row.id}><span><b className="category-dot" />{row.category}</span><span>{row.description}</span><span>{row.date}</span><strong>{currency} {row.displayAmount}</strong><span className="row-actions"><button className="icon-button" title="Edit expense" onClick={() => editExpense(row)}><Pencil size={14} /></button><button className="icon-button" title="Delete expense" onClick={() => removeExpense(row)}><Trash2 size={14} /></button></span></div>)}
      </div>
      <div><button disabled={page <= 1} onClick={() => setPage(page - 1)}>Previous</button> <span>Page {page} of {totalPages}</span> <button disabled={page >= totalPages} onClick={() => setPage(page + 1)}>Next</button></div>
    </section>
    {modal && <div className="budget-modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) closeModal() }}>
      <form className="budget-modal" onSubmit={submitModal} onMouseDown={(event) => event.stopPropagation()}>
        <div className="budget-modal-header">
          <div><span className="eyebrow">Trip finances</span><h2>{modal === 'expense' ? 'Edit expense' : modal === 'category' ? 'Edit category' : modal === 'new-category' ? 'Add category' : modal === 'create-budget' ? 'Create budget' : 'Edit budget'}</h2></div>
          <button type="button" className="budget-modal-close" onClick={closeModal} aria-label="Close">×</button>
        </div>
        {modal === 'expense' && <><label>Category<select value={modalValues.category || ''} onChange={(event) => setModalValues({ ...modalValues, category: event.target.value })}>{categories.map((category) => <option key={category.id}>{category.name}</option>)}{!categories.length && <><option>Stay</option><option>Transport</option><option>Experience</option><option>Food</option></>}</select></label><label>Description<input value={modalValues.description || ''} onChange={(event) => setModalValues({ ...modalValues, description: event.target.value })} /></label><label>Amount<input type="number" min="0.01" step="0.01" value={modalValues.amount || ''} onChange={(event) => setModalValues({ ...modalValues, amount: event.target.value })} /></label><label>Date<input type="date" value={modalValues.expenseDate || ''} onChange={(event) => setModalValues({ ...modalValues, expenseDate: event.target.value })} /></label></>}
        {['budget', 'create-budget'].includes(modal) && <label>Total budget allocation<input autoFocus type="number" min="0.01" step="0.01" value={modalValues.amount || ''} onChange={(event) => setModalValues({ ...modalValues, amount: event.target.value })} /></label>}
        {['category', 'new-category'].includes(modal) && <><label>Category name<input autoFocus value={modalValues.name || ''} onChange={(event) => setModalValues({ ...modalValues, name: event.target.value })} /></label><label>Allocated amount<input type="number" min="0.01" step="0.01" value={modalValues.allocatedAmount || ''} onChange={(event) => setModalValues({ ...modalValues, allocatedAmount: event.target.value })} /></label></>}
        {modalError && <div className="form-error">{modalError}</div>}
        <div className="budget-modal-actions"><button type="button" className="button button-light" onClick={closeModal}>Cancel</button><button type="submit" className="button button-dark" disabled={modalBusy}>{modalBusy ? 'Saving...' : 'Save changes'}</button></div>
      </form>
    </div>}
  </>
}
