using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace TravelWise.API.Services;

public interface IEmailSender
{
    Task SendTripInvitationAsync(string recipient, string destination, string invitationUrl, CancellationToken cancellationToken);
}

public sealed class EmailSender(IOptions<EmailOptions> options, ILogger<EmailSender> logger) : IEmailSender
{
    private readonly EmailOptions _options = options.Value;
    private readonly ILogger<EmailSender> _logger = logger;

    public async Task SendTripInvitationAsync(string recipient, string destination, string invitationUrl, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.Host) || string.IsNullOrWhiteSpace(_options.FromAddress))
            throw new InvalidOperationException("SMTP email is not configured. Set Email:Host and Email:FromAddress before sending invitations.");

        using var message = new MailMessage
        {
            From = new MailAddress(_options.FromAddress, _options.FromName),
            Subject = $"You are invited to collaborate on a {destination} trip",
            IsBodyHtml = true,
            Body = $"""
                    <p>You have been invited to collaborate on a TravelWise trip to <strong>{WebUtility.HtmlEncode(destination)}</strong>.</p>
                    <p><a href="{WebUtility.HtmlEncode(invitationUrl)}">Accept or review this invitation</a></p>
                    <p>This invitation expires in 7 days.</p>
                    """
        };
        message.To.Add(recipient);

        using var client = new SmtpClient(_options.Host, _options.Port)
        {
            EnableSsl = _options.EnableSsl,
            Credentials = new NetworkCredential(_options.Username, _options.Password)
        };
        await client.SendMailAsync(message, cancellationToken);
        _logger.LogInformation("Trip invitation email sent to {Recipient}", recipient);
    }
}
