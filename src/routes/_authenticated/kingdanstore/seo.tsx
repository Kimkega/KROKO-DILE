import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Search, Globe, HelpCircle, Save, Plus, Trash2, CheckCircle2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export const Route = createFileRoute("/_authenticated/kingdanstore/seo")({
  component: SeoAdminPage,
});

function SeoAdminPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState("settings");

  // 1. Load global SEO settings
  const { data: seoSettings, isLoading: loadingSettings } = useQuery({
    queryKey: ["admin", "seo-settings"],
    queryFn: async () => {
      const { data, error } = await supabase.from("seo_settings").select("*").limit(1).single();
      if (error && error.code !== "PGRST116") throw error;
      return data ?? {
        default_title: "KROKO DILE — Luxury Leather Bags in Kenya",
        title_suffix: " | KROKO DILE",
        default_description: "Hand-finished luxury leather bags for men and women. M-Pesa checkout and countrywide delivery in Kenya.",
        default_keywords: "luxury bags Kenya, leather handbags Nairobi, men bags Kenya, women handbags",
        organization_name: "KROKO DILE",
        sitemap_enabled: true,
        indexing_enabled: true,
      };
    },
  });

  // 2. Load SEO per-page mappings
  const { data: seoPages = [], isLoading: loadingPages } = useQuery({
    queryKey: ["admin", "seo-pages"],
    queryFn: async () => {
      const { data, error } = await supabase.from("seo_pages").select("*").order("sort_order");
      if (error) throw error;
      return data ?? [];
    },
  });

  // 3. Load FAQs
  const { data: faqs = [], isLoading: loadingFaqs } = useQuery({
    queryKey: ["admin", "faqs"],
    queryFn: async () => {
      const { data, error } = await supabase.from("faqs").select("*").order("sort_order");
      if (error) throw error;
      return data ?? [];
    },
  });

  // Form states for global settings
  const [formSettings, setFormSettings] = useState<any>(null);

  const currentSettings = formSettings || seoSettings || {};

  // Mutation to save global SEO settings
  const saveSettingsMutation = useMutation({
    mutationFn: async (updated: any) => {
      if (updated.id) {
        const { error } = await supabase.from("seo_settings").update(updated).eq("id", updated.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("seo_settings").insert([updated]);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      toast.success("SEO settings saved successfully");
      queryClient.invalidateQueries({ queryKey: ["admin", "seo-settings"] });
    },
    onError: (err: any) => toast.error(err.message),
  });

  // FAQ Add/Delete
  const [newQuestion, setNewQuestion] = useState("");
  const [newAnswer, setNewAnswer] = useState("");
  const [newCategory, setNewCategory] = useState("general");

  const addFaqMutation = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from("faqs").insert([
        { question: newQuestion, answer: newAnswer, category: newCategory, active: true },
      ]);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("FAQ added");
      setNewQuestion("");
      setNewAnswer("");
      queryClient.invalidateQueries({ queryKey: ["admin", "faqs"] });
    },
    onError: (err: any) => toast.error(err.message),
  });

  const deleteFaqMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("faqs").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("FAQ deleted");
      queryClient.invalidateQueries({ queryKey: ["admin", "faqs"] });
    },
    onError: (err: any) => toast.error(err.message),
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-3xl">SEO & Search Engines</h1>
        <p className="text-xs text-muted-foreground">
          Manage meta titles, descriptions, search engine indexing, sitemaps, and FAQs for Google rich results.
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-3 max-w-md">
          <TabsTrigger value="settings" className="gap-2">
            <Globe className="size-4" /> Global Settings
          </TabsTrigger>
          <TabsTrigger value="pages" className="gap-2">
            <Search className="size-4" /> Page Mapping
          </TabsTrigger>
          <TabsTrigger value="faqs" className="gap-2">
            <HelpCircle className="size-4" /> FAQs
          </TabsTrigger>
        </TabsList>

        {/* Global Settings */}
        <TabsContent value="settings" className="mt-6 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Default Search Engine Meta</CardTitle>
              <CardDescription>Configures default title tags, descriptions, and site indexing behavior.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Default Page Title</Label>
                <Input
                  value={currentSettings.default_title ?? ""}
                  onChange={(e) => setFormSettings({ ...currentSettings, default_title: e.target.value })}
                  placeholder="KROKO DILE — Luxury Leather Bags in Kenya"
                />
              </div>

              <div>
                <Label>Title Suffix</Label>
                <Input
                  value={currentSettings.title_suffix ?? ""}
                  onChange={(e) => setFormSettings({ ...currentSettings, title_suffix: e.target.value })}
                  placeholder=" | KROKO DILE"
                />
              </div>

              <div>
                <Label>Default Meta Description</Label>
                <Textarea
                  value={currentSettings.default_description ?? ""}
                  onChange={(e) => setFormSettings({ ...currentSettings, default_description: e.target.value })}
                  placeholder="Hand-finished luxury leather bags for men and women..."
                  rows={3}
                />
              </div>

              <div>
                <Label>Default Keywords (comma-separated)</Label>
                <Input
                  value={currentSettings.default_keywords ?? ""}
                  onChange={(e) => setFormSettings({ ...currentSettings, default_keywords: e.target.value })}
                  placeholder="luxury bags Kenya, leather handbags Nairobi..."
                />
              </div>

              <div className="flex items-center justify-between rounded-lg border p-4">
                <div>
                  <p className="font-medium text-sm">Allow Search Engine Indexing</p>
                  <p className="text-xs text-muted-foreground">Controls robots.txt and googlebot meta tags.</p>
                </div>
                <Switch
                  checked={currentSettings.indexing_enabled ?? true}
                  onCheckedChange={(val) => setFormSettings({ ...currentSettings, indexing_enabled: val })}
                />
              </div>

              <div className="flex items-center justify-between rounded-lg border p-4">
                <div>
                  <p className="font-medium text-sm">XML Sitemap Generation</p>
                  <p className="text-xs text-muted-foreground">Auto-generates sitemap.xml for Google Search Console.</p>
                </div>
                <Switch
                  checked={currentSettings.sitemap_enabled ?? true}
                  onCheckedChange={(val) => setFormSettings({ ...currentSettings, sitemap_enabled: val })}
                />
              </div>

              <Button
                onClick={() => saveSettingsMutation.mutate(currentSettings)}
                disabled={saveSettingsMutation.isPending}
                className="bg-gold-gradient text-accent-foreground"
              >
                <Save className="mr-2 size-4" /> Save SEO Settings
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Page Mapping */}
        <TabsContent value="pages" className="mt-6 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Page-by-Page SEO Mapping</CardTitle>
              <CardDescription>Custom titles and descriptions mapped for specific store paths.</CardDescription>
            </CardHeader>
            <CardContent>
              {loadingPages ? (
                <p className="text-xs text-muted-foreground">Loading pages...</p>
              ) : (
                <div className="space-y-4">
                  {seoPages.map((page: any) => (
                    <div key={page.id} className="rounded-lg border p-4 space-y-2 bg-card">
                      <div className="flex items-center justify-between">
                        <span className="font-mono text-xs font-semibold text-accent">{page.path}</span>
                        <span className="text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground">{page.label}</span>
                      </div>
                      <p className="text-xs font-medium">{page.title || "Default title used"}</p>
                      <p className="text-xs text-muted-foreground">{page.description || "Default description used"}</p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* FAQs */}
        <TabsContent value="faqs" className="mt-6 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Add New FAQ</CardTitle>
              <CardDescription>FAQs generate JSON-LD FAQPage rich snippets for Google search listings.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <Label>Question</Label>
                <Input
                  value={newQuestion}
                  onChange={(e) => setNewQuestion(e.target.value)}
                  placeholder="e.g. How long does upcountry delivery take?"
                />
              </div>
              <div>
                <Label>Answer</Label>
                <Textarea
                  value={newAnswer}
                  onChange={(e) => setNewAnswer(e.target.value)}
                  placeholder="e.g. Upcountry deliveries arrive within 2-4 working days via Fargo Courier or SACCO."
                  rows={2}
                />
              </div>
              <Button
                onClick={() => addFaqMutation.mutate()}
                disabled={!newQuestion || !newAnswer || addFaqMutation.isPending}
                className="bg-gold-gradient text-accent-foreground"
              >
                <Plus className="mr-2 size-4" /> Add FAQ
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Existing FAQs ({faqs.length})</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {loadingFaqs ? (
                <p className="text-xs text-muted-foreground">Loading FAQs...</p>
              ) : (
                faqs.map((faq: any) => (
                  <div key={faq.id} className="flex items-start justify-between gap-4 rounded-lg border p-4 bg-card">
                    <div>
                      <p className="font-semibold text-sm">{faq.question}</p>
                      <p className="mt-1 text-xs text-muted-foreground">{faq.answer}</p>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="text-destructive hover:text-destructive/80"
                      onClick={() => deleteFaqMutation.mutate(faq.id)}
                    >
                      <Trash2 className="size-4" />
                    </Button>
                  </div>
                ))
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
