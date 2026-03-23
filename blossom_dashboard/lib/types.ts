export type Profile = {
  id: string;
  email: string;
  display_name: string | null;
  avatar_path: string | null;
  role: 'user' | 'admin';
  notifications_enabled: boolean;
  created_at: string;
  updated_at: string;
};

export type AiSettings = {
  provider: string;
  model: string;
  system_prompt: string;
  temperature: number;
  max_tokens: number;
  is_enabled: boolean;
  has_api_key: boolean;
  connection_last_tested_at: string | null;
  connection_last_status: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
};

export type AiConnectionTestResult = {
  success: boolean;
  message: string;
  tested_at: string;
  model: string;
};

export type Plant = {
  id: string;
  common_name: string;
  scientific_name: string | null;
  short_description: string;
  image_path: string | null;
  water_requirements: string;
  light_requirements: string;
  temperature: string;
  pet_safe: boolean;
  source: 'admin' | 'ai_image_discovery';
  ai_confidence: number | null;
  created_by_user_id: string | null;
  reviewed_by_admin: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type PlantMutationPayload = Partial<{
  common_name: string;
  scientific_name: string | null;
  short_description: string;
  image_path: string | null;
  water_requirements: string;
  light_requirements: string;
  temperature: string;
  pet_safe: boolean;
  source: 'admin' | 'ai_image_discovery';
  ai_confidence: number | null;
  reviewed_by_admin: boolean;
  is_active: boolean;
}>;

export type CommunityProfileSummary = {
  id: string;
  display_name: string | null;
  avatar_path: string | null;
};

export type CommunityComment = {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  hidden_by_admin: boolean;
  created_at: string;
  updated_at: string;
  author: CommunityProfileSummary;
};

export type CommunityPost = {
  id: string;
  user_id: string;
  content: string;
  image_path: string | null;
  hidden_by_admin: boolean;
  created_at: string;
  updated_at: string;
  author: CommunityProfileSummary;
  comments: CommunityComment[];
  likes_count: number;
  comments_count: number;
  liked_by_me: boolean;
};

export type CommunityFeed = {
  items: CommunityPost[];
  meta: {
    count: number;
  };
};

export type Report = {
  id: string;
  post_id: string | null;
  comment_id: string | null;
  reporter_user_id: string;
  reporter: CommunityProfileSummary | null;
  reason: string;
  status: 'pending' | 'reviewed' | 'dismissed';
  reviewed_by: string | null;
  created_at: string;
  updated_at: string;
  post_content?: string | null;
  comment_content?: string | null;
  target_author?: CommunityProfileSummary | null;
};

export type AuditLogEntry = {
  id: string;
  admin_user_id: string;
  admin_display_name: string | null;
  action: string;
  entity_type: string;
  entity_id: string | null;
  metadata: Record<string, any>;
  created_at: string;
};
