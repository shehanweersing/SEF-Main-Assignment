import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import api from '../../api/axios';

// Define the strict validation schema
const budgetSchema = z.object({
    tripId: z.coerce.number().min(1, "Trip ID is required"),
    amount: z.coerce.number().positive("Amount strictly must be greater than zero"),
    category: z.string().min(2, "Category is required")
});

export default function BudgetForm() {
    const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm({
        resolver: zodResolver(budgetSchema)
    });

    const onSubmit = async (data) => {
        try {
            await api.post('/Budget/expenses', data);
            alert("Expense added successfully!");
            reset();
        } catch (error) {
            console.error("API Error:", error);
            alert("Failed to add expense.");
        }
    };

    return (
        <form onSubmit={handleSubmit(onSubmit)} className="max-w-md p-4 bg-white rounded shadow">
            <h2 className="mb-4 text-xl font-bold">Add Expense</h2>
            
            <div className="mb-4">
                <label className="block mb-1 text-sm font-medium">Trip ID</label>
                <input {...register('tripId')} type="number" className="w-full p-2 border rounded" />
                {errors.tripId && <p className="mt-1 text-sm text-red-500">{errors.tripId.message}</p>}
            </div>

            <div className="mb-4">
                <label className="block mb-1 text-sm font-medium">Amount ($)</label>
                <input {...register('amount')} type="number" step="0.01" className="w-full p-2 border rounded" />
                {errors.amount && <p className="mt-1 text-sm text-red-500">{errors.amount.message}</p>}
            </div>

            <div className="mb-4">
                <label className="block mb-1 text-sm font-medium">Category</label>
                <input {...register('category')} type="text" className="w-full p-2 border rounded" />
                {errors.category && <p className="mt-1 text-sm text-red-500">{errors.category.message}</p>}
            </div>

            <button disabled={isSubmitting} type="submit" className="w-full p-2 text-white bg-blue-600 rounded hover:bg-blue-700">
                {isSubmitting ? 'Saving...' : 'Save Expense'}
            </button>
        </form>
    );
}