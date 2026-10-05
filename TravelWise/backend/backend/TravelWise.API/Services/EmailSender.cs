using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace TravelWise.API.Services;

public interface IEmailSender
{
    Task SendTripInvitationAsync(string recipient, string destination, string invitationUrl, CancellationToken cancellationToken);
}

public sealed class EmailConfigurationException(string message) : InvalidOperationException(message);

public sealed class EmailDeliveryException(string message, Exception innerException) : Exception(message, innerException);

public sealed class EmailSender(IOptions<EmailOptions> options, ILogger<EmailSender> logger) : IEmailSender
{
    private readonly EmailOptions _options = options.Value;
    private readonly ILogger<EmailSender> _logger = logger;

    public async Task SendTripInvitationAsync(string recipient, string destination, string invitationUrl, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.Host) ||
            string.IsNullOrWhiteSpace(_options.Username) ||
            string.IsNullOrWhiteSpace(_options.Password) ||
            string.IsNullOrWhiteSpace(_options.FromAddress) ||
            _options.Port <= 0)
            throw new EmailConfigurationException("SMTP email is not configured. Set Email:Host, Email:Port, Email:Username, Email:Password, and Email:FromAddress using a Gmail app password in user secrets or environment variables.");

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
        try
        {
            await client.SendMailAsync(message, cancellationToken);
        }
        catch (SmtpException exception)
        {
            _logger.LogError(exception, "SMTP delivery failed for {Recipient} using {Host}:{Port}", recipient, _options.Host, _options.Port);
            throw new EmailDeliveryException("The invitation email could not be delivered. For Gmail, use smtp.gmail.com, port 587 with SSL enabled, and a 16-character Gmail app password (not your normal Gmail password).", exception);
        }
        _logger.LogInformation("Trip invitation email sent to {Recipient}", recipient);
    }
}
