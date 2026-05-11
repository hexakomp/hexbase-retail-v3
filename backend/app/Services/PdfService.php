<?php

namespace App\Services;

use App\Models\PdfTemplate;
use Dompdf\Dompdf;
use Dompdf\Options;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class PdfService
{
    /**
     * Render a Blade view to PDF. If a custom PdfTemplate is set as default
     * for the given document_type, its template_html is used instead of the Blade view.
     *
     * @param  string  $view    Blade view name, e.g. 'pdf.sales_invoice'
     * @param  array   $data    Data to pass to the view
     * @param  string  $orientation  'portrait' | 'landscape'
     * @param  string|null $documentType  e.g. 'sales_invoice' — checks PdfTemplate table
     * @return string  Raw PDF binary content
     */
    public function render(string $view, array $data = [], string $orientation = 'portrait', ?string $documentType = null): string
    {
        $html = $this->resolveHtml($view, $data, $documentType);

        $options = new Options();
        $options->set('isHtml5ParserEnabled', true);
        $options->set('isPhpEnabled', false);
        $options->set('isRemoteEnabled', false);
        $options->set('defaultFont', 'DejaVu Sans');

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml($html);
        $dompdf->setPaper('A4', $orientation);
        $dompdf->render();

        return $dompdf->output();
    }

    /**
     * Render a Blade view to PDF and save to storage, returning the stored path.
     *
     * @param  string  $view
     * @param  array   $data
     * @param  string  $storagePath  e.g. 'pdfs/invoices/INV-0001.pdf'
     * @param  string  $disk         Storage disk name
     * @return string  The stored file path
     */
    public function save(
        string $view,
        array $data = [],
        string $storagePath = '',
        string $disk = 'local'
    ): string {
        $pdfContent = $this->render($view, $data);

        if (! $storagePath) {
            $storagePath = 'pdfs/' . Str::uuid() . '.pdf';
        }

        Storage::disk($disk)->put($storagePath, $pdfContent);

        return $storagePath;
    }

    /**
     * Return a StreamedResponse for inline/download display.
     */
    public function download(string $view, array $data = [], string $filename = 'document.pdf'): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $pdfContent = $this->render($view, $data);

        return response()->streamDownload(function () use ($pdfContent) {
            echo $pdfContent;
        }, $filename, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ]);
    }

    /**
     * Resolve HTML from a custom template (if set as default) or Blade view.
     */
    private function resolveHtml(string $view, array $data, ?string $documentType): string
    {
        if ($documentType) {
            try {
                $tpl = PdfTemplate::forType($documentType)->default()->first();
                if ($tpl) {
                    // Render via Blade string compiler
                    $html = $tpl->template_html;
                    // Simple variable interpolation using PHP template replacement
                    foreach ($data as $key => $value) {
                        if (is_scalar($value)) {
                            $html = str_replace('{{ $' . $key . ' }}', e((string) $value), $html);
                        }
                    }
                    return $html;
                }
            } catch (\Throwable) {
                // Fall through to Blade view on any DB error
            }
        }

        return view($view, $data)->render();
    }
}
