<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Abstract base model that forces the "tenant" database connection
 * for all derived Eloquent models.
 */
abstract class TenantModel extends Model
{
    /**
     * The database connection to use for this model.
     *
     * @var string
     */
    protected $connection = 'tenant';
}
