-- Align private media storage with the app's video picker limit (100 MB).
UPDATE storage.buckets
SET file_size_limit = 104857600
WHERE id = 'ours-direct-media';
