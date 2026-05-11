<?php

namespace App\Observers;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ActivityLogObserver
{
    public function created(Model $model): void
    {
        $this->log('created', $model);
    }

    public function updated(Model $model): void
    {
        $this->log('updated', $model, $model->getDirty());
    }

    public function deleted(Model $model): void
    {
        $this->log('deleted', $model);
    }

    private function log(string $event, Model $model, array $properties = []): void
    {
        try {
            DB::connection('tenant')->table('activity_log')->insert([
                'event'        => $event,
                'subject_type' => get_class($model),
                'subject_id'   => $model->getKey(),
                'causer_type'  => Auth::check() ? get_class(Auth::user()) : null,
                'causer_id'    => Auth::id(),
                'properties'   => json_encode($properties),
                'created_at'   => now(),
                'updated_at'   => now(),
            ]);
        } catch (\Throwable $e) {
            // Never let logging crash a request
            \Illuminate\Support\Facades\Log::warning('ActivityLogObserver failed: ' . $e->getMessage());
        }
    }
}
