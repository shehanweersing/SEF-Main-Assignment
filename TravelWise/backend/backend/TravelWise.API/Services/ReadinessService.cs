using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;

namespace TravelWise.API.Services
{
    public class ReadinessService
    {
        private readonly ApplicationDbContext _context;

        public ReadinessService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<TravelDocument> AddDocumentAsync(CreateDocumentDto dto)
        {
            // Enforce BR-READY-01: Non-expired docs only[cite: 3]
            if (dto.ExpiryDate.Date <= DateTime.UtcNow.Date)
                throw new ArgumentException("Document is already expired and cannot be used for travel (BR-READY-01).");

            var document = new TravelDocument
            {
                TripId = dto.TripId,
                DocumentType = dto.DocumentType,
                DocumentNumber = dto.DocumentNumber,
                ExpiryDate = dto.ExpiryDate
            };

            _context.TravelDocuments.Add(document);
            await _context.SaveChangesAsync();
            return document;
        }
    }
}