<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$dbs = ['hexbase_demo', 'hexbase_tenant_demo'];
$password = 'password';
$hash = Hash::make($password);

echo "Target Hash: $hash\n";

foreach ($dbs as $db) {
    echo "Processing $db...\n";
    try {
        $users = DB::connection('central')->table("$db.users")->get();
        echo "Found " . count($users) . " users in $db:\n";
        foreach ($users as $user) {
            echo "- " . $user->email . " (Hash: " . $user->password . ")\n";
        }

        $count = DB::connection('central')
            ->table("$db.users")
            ->where('email', 'admin@hexbase.com')
            ->update(['password' => $hash]);

        echo "Updated $count rows in $db.\n";

        $user = DB::connection('central')
            ->table("$db.users")
            ->where('email', 'admin@hexbase.com')
            ->first();

        if ($user) {
            echo "Current hash in $db: " . $user->password . "\n";
            if (Hash::check($password, $user->password)) {
                echo "VERIFIED: Password check PASSED for $db.\n";
            } else {
                echo "FAILED: Password check FAILED for $db.\n";
            }
        } else {
            echo "Admin user not found in $db.\n";
        }
    } catch (\Exception $e) {
        echo "Error in $db: " . $e->getMessage() . "\n";
    }
}
