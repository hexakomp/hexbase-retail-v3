<?php

namespace App\Exceptions;

use RuntimeException;

class AccountingImbalanceException extends RuntimeException
{
    public function __construct(string $message = 'Accounting entries do not balance (debits ≠ credits).', int $code = 0, ?\Throwable $previous = null)
    {
        parent::__construct($message, $code, $previous);
    }
}
