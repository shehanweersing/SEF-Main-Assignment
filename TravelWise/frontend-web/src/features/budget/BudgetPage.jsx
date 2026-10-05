import { Pencil, Plus, Trash2, Wallet } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { budgetApi, getOrCreateBudget, getOrCreateTrip } from '../../api/travelWiseApi'
import BudgetHealthCard from './BudgetHealthCard'
import { useAuth } from '../../context/AuthContext'

const budgetSchema = z.object({
  category: z.string().min(1, 'Choose a category'),
  description: z.string().min(2, 'Add a short description'),
  amount: z.coerce.number().positive('Amount must be greater than 0'),
  expenseDate: z.string().min(1, 'Select a date'),
})

const errorText = (error, fallback) => error.response?.data?.detail || error.response?.data?.message || error.response?.data || fallback

export default function BudgetPage() {
  const { user } = useAuth()
  const [trip, setTrip] = useState(null)
  const [rows, setRows] = useState([])
  const [budget, setBudget] = useState(null)
  const [categories, setCategories] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [serverError, setServerError] = useState('')
  const [filter, setFilter] = useState('')
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const pageSize = 10
  const { register, handleSubmit, reset, formState: { errors } } = useForm({ resolver: zodResolver(budgetSchema) })

  useEffect(() => {
    if (!user?.id) return
    getOrCreateTrip(user.id).then(async (currentTrip) => {
      setTrip(currentTrip)
      const currentBudget = await getOrCreateBudget(currentTrip.id)
      setBudget(currentBudget)
      const categoriesResponse = await budgetApi.listCategories(currentBudget.id)
      setCategories(categoriesResponse.data)
    }).catch((error) => setServerError(errorText(error, 'Could not load budget data.')))
  }, [user?.id])

  useEffect(() => {
    if (!budget) return
    budgetApi.listExpenses(budget.id, { category: filter || undefined, page, pageSize }).then(({ data }) => {
      const expenses = Array.isArray(data) ? data : data.items
      setTotal(Array.isArray(data) ? expenses.length : data.total)
      setRows(expenses.map((expense) => ({ ...expense, date: expense.expenseDate, amount: `$${Number(expense.amount).toFixed(2)}` })))
    }).catch((error) => setServerError(errorText(error, 'Could not load expenses.')))
  }, [budget, filter, page])

  async function submit(values) {
    setServerError('')
    try {
      await budgetApi.addExpense({ ...values, budgetId: budget.id, amount: Number(values.amount) })
      reset()
      setShowForm(false)
      setPage(1)
      const { data } = await budgetApi.listExpenses(budget.id, { category: filter || undefined, page: 1, pageSize })
      setRows((Array.isArray(data) ? data : data.items).map((expense) => ({ ...expense, date: expense.expenseDate, amount: `$${Number(expense.amount).toFixed(2)}` })))
    } catch (error) { setServerError(errorText(error, 'Could not save this expense.')) }
  }

  async function editBudget() {
    const value = window.prompt('Total budget allocation', String(budget?.totalAllocation || ''))
    const amount = Number(value)
    if (!value || !Number.isFinite(amount) || amount <= 0) return
    try {
      const { data } = await budgetApi.updateBudget(budget.id, { tripId: budget.tripId, totalAllocation: amount, currency: budget.currency })
      setBudget(data)
    } catch (error) { setServerError(errorText(error, 'Could not update the budget.')) }
  }

  async function editExpense(row) {
    const amount = Number(window.prompt('Expense amount', String(Number(row.amount.replace('$', '')))))
    if (!Number.isFinite(amount) || amount <= 0) return
    try {
      await budgetApi.updateExpense(row.id, { budgetId: budget.id, category: row.category, description: row.description, amount, expenseDate: row.expenseDate || row.date })
      setPage(1)
    } catch (error) { setServerError(errorText(error, 'Could not update this expense.')) }
  }

  async function removeExpense(row) {
    if (!row.id || !window.confirm('Delete this expense?')) return
    try { await budgetApi.deleteExpense(row.id); setPage(1) } catch (error) { setServerError(errorText(error, 'Could not delete this expense.')) }
  }

  async function addCategory() {
    const name = window.prompt('Category name')
    const allocatedAmount = Number(window.prompt('Category allocation'))
    if (!name || !Number.isFinite(allocatedAmount) || allocatedAmount <= 0) return
    try {
      const { data } = await budgetApi.addCategory(budget.id, { name, allocatedAmount })
      setCategories((current) => [...current, data])
    } catch (error) { setServerError(errorText(error, 'Could not add this category.')) }
  }

  const spent = rows.reduce((totalAmount, row) => totalAmount + Number(String(row.amount).replace('$', '')), 0)
  const currency = budget?.currency || trip?.currency || 'USD'
  return <><div className="page-intro"><div><span className="eyebrow">Trip finances</span><h1>Budget, beautifully clear.</h1><p>Keep the numbers in view without letting them take over.</p></div><span><button className="button button-light" onClick={editBudget} disabled={!budget}><Pencil size={14} /> Edit allocation</button> <button className="button button-coral" onClick={() => setShowForm(!showForm)}><Plus size={16} /> Add expense</button></span></div>{trip && <BudgetHealthCard tripId={trip.id} currency={currency} />}<div className="feature-summary"><div className="summary-icon"><Wallet size={20} /></div><div><span>Total allocated</span><strong>{currency} {Number(budget?.totalAllocation || 0).toFixed(2)}</strong></div><div><span>Current page spend</span><strong>{currency} {spent.toFixed(2)}</strong></div><div><span>Remaining</span><strong className="positive">{currency} {Math.max(0, Number(budget?.totalAllocation || 0) - spent).toFixed(2)}</strong></div></div>{serverError && <div className="form-error">{String(serverError)}</div>}{budget && <section className="table-panel"><div className="table-heading"><h2>Category allocations</h2><button className="button button-light" onClick={addCategory}><Plus size={14} /> Add category</button></div>{categories.length ? categories.map((category) => <div className="table-row" key={category.id}><span>{category.name}</span><strong>{currency} {Number(category.allocatedAmount).toFixed(2)}</strong></div>) : <p>No category allocations configured.</p>}</section>}{showForm && <form className="inline-form" onSubmit={handleSubmit(submit)}><label>Category<select {...register('category')}><option value="">Select</option>{categories.map((category) => <option key={category.id}>{category.name}</option>)}{!categories.length && <><option>Stay</option><option>Transport</option><option>Experience</option><option>Food</option></>}</select>{errors.category && <small className="field-error">{errors.category.message}</small>}</label><label>Description<input {...register('description')} placeholder="What was this for?" />{errors.description && <small className="field-error">{errors.description.message}</small>}</label><label>Amount<input type="number" step="0.01" {...register('amount')} placeholder="0.00" />{errors.amount && <small className="field-error">{errors.amount.message}</small>}</label><label>Date<input type="date" {...register('expenseDate')} />{errors.expenseDate && <small className="field-error">{errors.expenseDate.message}</small>}</label><button className="button button-dark" type="submit">Save</button></form>}<section className="table-panel"><div className="table-heading"><h2>Recent expenses</h2><span>{total} items</span></div><label>Filter by category <input value={filter} onChange={(event) => { setFilter(event.target.value); setPage(1) }} placeholder="All categories" /></label><div className="data-table"><div className="table-row table-header"><span>Category</span><span>Description</span><span>Date</span><span>Amount</span><span /></div>{rows.map((row, i) => <div className="table-row" key={`${row.id || row.description}-${i}`}><span><b className="category-dot" />{row.category}</span><span>{row.description}</span><span>{row.date}</span><strong>{row.amount}</strong>{row.id && <span className="row-actions"><button className="icon-button" title="Edit expense" onClick={() => editExpense(row)}><Pencil size={14} /></button><button className="icon-button" title="Delete expense" onClick={() => removeExpense(row)}><Trash2 size={14} /></button></span>}</div>)}</div><div><button disabled={page <= 1} onClick={() => setPage(page - 1)}>Previous</button> <span>Page {page}</span> <button disabled={page * pageSize >= total} onClick={() => setPage(page + 1)}>Next</button></div></section></>
}
