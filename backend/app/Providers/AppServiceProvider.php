<?php

namespace App\Providers;

use App\Models\CreditNote;
use App\Models\DebitNote;
use App\Models\DeliveryChallan;
use App\Models\Expense;
use App\Models\PurchaseInvoice;
use App\Models\PurchaseOrder;
use App\Models\SalesInvoice;
use App\Observers\ActivityLogObserver;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(
            \Illuminate\Contracts\Debug\ExceptionHandler::class,
            \App\Exceptions\Handler::class,
        );
    }

    public function boot(): void
    {
        // Implicitly grant "super-admin" role all permissions
        Gate::before(function ($user, $ability) {
            return $user->hasRole('super-admin') ? true : null;
        });

        // Rate limiting
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(120)->by($request->user()?->id ?: $request->ip());
        });

        // Activity log observers
        foreach ([
            SalesInvoice::class,
            PurchaseInvoice::class,
            CreditNote::class,
            DebitNote::class,
            Expense::class,
            PurchaseOrder::class,
            DeliveryChallan::class,
        ] as $model) {
            $model::observe(ActivityLogObserver::class);
        }
    }
}
