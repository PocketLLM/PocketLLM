-- Add onboarding support fields to profiles table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS age INTEGER CHECK (age IS NULL OR (age >= 13 AND age <= 120)),
  ADD COLUMN IF NOT EXISTS onboarding_responses JSONB;
