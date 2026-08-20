import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { SiteShell } from "@/components/layout/SiteShell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: "Admin Sign In — KROKO DILE" },
      { name: "description", content: "Sign in or register to manage the KROKO DILE store, orders and settings." },
      { property: "og:title", content: "Admin Sign In — KROKO DILE" },
      { property: "og:description", content: "Staff access to the KROKO DILE admin dashboard." },
    ],
  }),
  component: Auth,
});

function Auth() {
  const navigate = useNavigate();
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    if (isSignUp) {
      const { data, error } = await supabase.auth.signUp({ email, password });
      if (error) {
        setLoading(false);
        toast.error(error.message);
        return;
      }
      if (data.user) {
        // Auto assign admin role for first staff user
        await supabase.from("user_roles").insert({ user_id: data.user.id, role: "admin" });
        toast.success("Account created successfully! Signing in...");
        if (data.session) {
          navigate({ to: "/kingdanstore" });
        } else {
          // If email confirmation is required
          toast.info("Please check your email to confirm your account or sign in.");
          setIsSignUp(false);
        }
      }
      setLoading(false);
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      setLoading(false);
      if (error) {
        toast.error(error.message);
        return;
      }
      toast.success("Welcome back!");
      navigate({ to: "/kingdanstore" });
    }
  }

  return (
    <SiteShell>
      <div className="mx-auto max-w-md px-6 py-20">
        <h1 className="font-display text-4xl">{isSignUp ? "Create Staff Account" : "Staff Sign In"}</h1>
        <p className="mt-2 text-xs text-muted-foreground">
          {isSignUp ? "Register a new admin account to manage KROKO DILE." : "Access store orders, inventory, and settings."}
        </p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-4">
          <div>
            <Label htmlFor="a-email">Email</Label>
            <Input id="a-email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@krokodile.co.ke" />
          </div>
          <div>
            <Label htmlFor="a-pass">Password</Label>
            <Input
              id="a-pass"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>

          <Button
            type="submit"
            disabled={loading}
            className="w-full bg-gold-gradient text-accent-foreground shadow-gold hover:opacity-90"
          >
            {loading ? (isSignUp ? "Creating account…" : "Signing in…") : isSignUp ? "Create Account" : "Sign In"}
          </Button>
        </form>

        <div className="mt-6 text-center">
          <button
            type="button"
            onClick={() => setIsSignUp((v) => !v)}
            className="text-xs text-accent underline hover:text-accent/80"
          >
            {isSignUp ? "Already have a staff account? Sign in" : "Need to create a staff account? Register"}
          </button>
        </div>
      </div>
    </SiteShell>
  );
}
