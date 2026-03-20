import { Link } from "@inertiajs/react";
import { Card, CardContent } from "@/components/ui/card";

export default function Privacy() {
  return (
    <div className="min-h-screen bg-background px-4 py-8">
      <div className="mx-auto max-w-2xl">
        <div className="text-center mb-6">
          <img src="/brand/genixo-horizontal-dark.png" alt="Genixo Restoration" className="h-10 mx-auto mb-3" />
        </div>

        <Card>
          <CardContent className="p-6 sm:p-8 prose prose-sm max-w-none">
            <h1 className="text-2xl font-bold text-foreground mb-1">Privacy Policy</h1>
            <p className="text-sm text-muted-foreground mb-6">Last updated: March 18, 2026</p>

            <p className="text-sm text-foreground leading-relaxed">
              Genixo Restoration Manager ("Genixo", "we", "us") provides incident management
              software for property restoration teams. This policy explains what data we collect,
              how we use it, and your rights.
            </p>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Information We Collect</h2>
            <p className="text-sm text-foreground leading-relaxed mb-2">
              We collect the following information when you use our service:
            </p>
            <ul className="text-sm text-foreground space-y-1.5 list-disc pl-5">
              <li><strong>Account information:</strong> name, email address, phone number, and job title</li>
              <li><strong>Organization data:</strong> company name, address, and contact details</li>
              <li><strong>Incident data:</strong> property details, damage descriptions, status updates, messages, and notes</li>
              <li><strong>Photos and documents:</strong> images and files you upload related to incidents</li>
              <li><strong>Usage data:</strong> login times, feature usage, and activity logs for security and support</li>
              <li><strong>Device information:</strong> browser type, operating system, and device identifiers when using our mobile app</li>
            </ul>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">How We Use Your Information</h2>
            <ul className="text-sm text-foreground space-y-1.5 list-disc pl-5">
              <li>Provide and operate the incident management platform</li>
              <li>Send notifications about incidents you're assigned to (email, SMS)</li>
              <li>Communicate with you about your account and service updates</li>
              <li>Maintain security and prevent unauthorized access</li>
              <li>Improve our service based on usage patterns</li>
            </ul>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Data Sharing</h2>
            <p className="text-sm text-foreground leading-relaxed">
              We do not sell your personal information. We share data only in these cases:
            </p>
            <ul className="text-sm text-foreground space-y-1.5 list-disc pl-5">
              <li><strong>Within your organization:</strong> team members in your organization can see incident data they're authorized to access</li>
              <li><strong>Between organizations:</strong> when a mitigation org and property management org collaborate on an incident, relevant data is shared between authorized users</li>
              <li><strong>Service providers:</strong> we use third-party services for hosting (Heroku/AWS), email delivery (Resend), and file storage (Amazon S3)</li>
              <li><strong>Legal requirements:</strong> when required by law or to protect rights and safety</li>
            </ul>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Data Retention</h2>
            <p className="text-sm text-foreground leading-relaxed">
              We retain your data for as long as your account is active or as needed to provide
              services. Incident records and associated photos are retained for the duration of
              your organization's subscription. If you request account deletion, we will remove
              your personal information within 30 days, except where we need to retain records
              for legal or business purposes.
            </p>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Data Security</h2>
            <p className="text-sm text-foreground leading-relaxed">
              We use industry-standard security measures including encrypted connections (TLS),
              secure password hashing, and access controls. All data is stored on servers located
              in the United States.
            </p>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Your Rights</h2>
            <p className="text-sm text-foreground leading-relaxed mb-2">
              You have the right to:
            </p>
            <ul className="text-sm text-foreground space-y-1.5 list-disc pl-5">
              <li>Access the personal data we hold about you</li>
              <li>Correct inaccurate information</li>
              <li>Request deletion of your account and personal data</li>
              <li>Export your data in a portable format</li>
              <li>Opt out of non-essential communications</li>
            </ul>
            <p className="text-sm text-foreground leading-relaxed mt-2">
              To exercise any of these rights, contact us at the email below.
            </p>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Camera and Photo Access</h2>
            <p className="text-sm text-foreground leading-relaxed">
              Our mobile app requests access to your device's camera and photo library so you can
              take and upload photos of property damage directly to incidents. We only access
              your camera or photos when you explicitly choose to capture or upload an image.
              Photos are uploaded to our secure servers and are only visible to authorized users
              on the relevant incident.
            </p>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Changes to This Policy</h2>
            <p className="text-sm text-foreground leading-relaxed">
              We may update this policy from time to time. We'll notify you of significant
              changes via email or an in-app notice.
            </p>

            <h2 className="text-lg font-semibold text-foreground mt-8 mb-3">Contact</h2>
            <p className="text-sm text-foreground leading-relaxed">
              If you have questions about this privacy policy or your data, contact us
              at <a href="mailto:privacy@genixorestoration.com" className="text-primary hover:underline">privacy@genixorestoration.com</a>.
            </p>
          </CardContent>
        </Card>

        <div className="text-center mt-6">
          <Link href="/login" className="text-sm text-muted-foreground hover:text-foreground">
            Back to login
          </Link>
        </div>
      </div>
    </div>
  );
}
