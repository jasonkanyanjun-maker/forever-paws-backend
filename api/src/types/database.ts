export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      letters: {
        Row: {
          ai_metadata: Json | null
          content: string
          created_at: string | null
          id: string
          mood: "happy" | "sad" | "loving" | "nostalgic" | "grateful" | null
          parent_letter_id: string | null
          pet_id: string
          replied_at: string | null
          type: "memorial" | "birthday" | "anniversary" | "daily" | "ai_reply" | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          ai_metadata?: Json | null
          content: string
          created_at?: string | null
          id?: string
          mood?: "happy" | "sad" | "loving" | "nostalgic" | "grateful" | null
          parent_letter_id?: string | null
          pet_id: string
          replied_at?: string | null
          type?: "memorial" | "birthday" | "anniversary" | "daily" | "ai_reply" | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          ai_metadata?: Json | null
          content?: string
          created_at?: string | null
          id?: string
          mood?: "happy" | "sad" | "loving" | "nostalgic" | "grateful" | null
          parent_letter_id?: string | null
          pet_id?: string
          replied_at?: string | null
          type?: "memorial" | "birthday" | "anniversary" | "daily" | "ai_reply" | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "letters_parent_letter_id_fkey"
            columns: ["parent_letter_id"]
            isOneToOne: false
            referencedRelation: "letters"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "letters_pet_id_fkey"
            columns: ["pet_id"]
            isOneToOne: false
            referencedRelation: "pets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "letters_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string | null
          data: Json | null
          id: string
          message: string
          read: boolean | null
          title: string
          type: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          data?: Json | null
          id?: string
          message: string
          read?: boolean | null
          title: string
          type: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          data?: Json | null
          id?: string
          message?: string
          read?: boolean | null
          title?: string
          type?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          created_at: string | null
          id: string
          order_id: string
          price: number
          product_id: string
          quantity: number
        }
        Insert: {
          created_at?: string | null
          id?: string
          order_id: string
          price: number
          product_id: string
          quantity: number
        }
        Update: {
          created_at?: string | null
          id?: string
          order_id?: string
          price?: number
          product_id?: string
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          created_at: string | null
          id: string
          payment_intent_id: string | null
          status: "pending" | "processing" | "shipped" | "delivered" | "cancelled"
          total_amount: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          payment_intent_id?: string | null
          status?: "pending" | "processing" | "shipped" | "delivered" | "cancelled"
          total_amount: number
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          payment_intent_id?: string | null
          status?: "pending" | "processing" | "shipped" | "delivered" | "cancelled"
          total_amount?: number
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      pets: {
        Row: {
          breed: string | null
          created_at: string | null
          date_of_birth: string | null
          date_of_passing: string | null
          description: string | null
          id: string
          is_memorial: boolean | null
          name: string
          personality: string | null
          photos: string[] | null
          type: "dog" | "cat" | "bird" | "fish" | "rabbit" | "hamster" | "other"
          updated_at: string | null
          user_id: string
        }
        Insert: {
          breed?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          date_of_passing?: string | null
          description?: string | null
          id?: string
          is_memorial?: boolean | null
          name: string
          personality?: string | null
          photos?: string[] | null
          type: "dog" | "cat" | "bird" | "fish" | "rabbit" | "hamster" | "other"
          updated_at?: string | null
          user_id: string
        }
        Update: {
          breed?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          date_of_passing?: string | null
          description?: string | null
          id?: string
          is_memorial?: boolean | null
          name?: string
          personality?: string | null
          photos?: string[] | null
          type?: "dog" | "cat" | "bird" | "fish" | "rabbit" | "hamster" | "other"
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "pets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          category: string
          created_at: string | null
          currency: string | null
          customization_options: Json | null
          description: string | null
          id: string
          image_url: string | null
          images: string[] | null
          is_active: boolean | null
          metadata: Json
          name: string
          price: number
          stock_quantity: number | null
          updated_at: string | null
        }
        Insert: {
          category: string
          created_at?: string | null
          currency?: string | null
          customization_options?: Json | null
          description?: string | null
          id?: string
          image_url?: string | null
          images?: string[] | null
          is_active?: boolean | null
          metadata?: Json
          name: string
          price: number
          stock_quantity?: number | null
          updated_at?: string | null
        }
        Update: {
          category?: string
          created_at?: string | null
          currency?: string | null
          customization_options?: Json | null
          description?: string | null
          id?: string
          image_url?: string | null
          images?: string[] | null
          is_active?: boolean | null
          metadata?: Json
          name?: string
          price?: number
          stock_quantity?: number | null
          updated_at?: string | null
        }
        Relationships: []
      }
      users: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          display_name: string | null
          email: string
          id: string
          phone: string | null
          updated_at: string | null
          username: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          display_name?: string | null
          email: string
          id?: string
          phone?: string | null
          updated_at?: string | null
          username?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          display_name?: string | null
          email?: string
          id?: string
          phone?: string | null
          updated_at?: string | null
          username?: string | null
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          id: string
          user_id: string | null
          name: string | null
          avatar_url: string | null
          hobbies: Json | null
          preferences: Json | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          user_id?: string | null
          name?: string | null
          avatar_url?: string | null
          hobbies?: Json | null
          preferences?: Json | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string | null
          name?: string | null
          avatar_url?: string | null
          hobbies?: Json | null
          preferences?: Json | null
          created_at?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      pet_photos: {
        Row: {
          id: string
          pet_id: string
          photo_url: string
          crop_data: Json | null
          is_primary: boolean | null
          uploaded_at: string | null
        }
        Insert: {
          id?: string
          pet_id: string
          photo_url: string
          crop_data?: Json | null
          is_primary?: boolean | null
          uploaded_at?: string | null
        }
        Update: {
          id?: string
          pet_id?: string
          photo_url?: string
          crop_data?: Json | null
          is_primary?: boolean | null
          uploaded_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pet_photos_pet_id_fkey"
            columns: ["pet_id"]
            isOneToOne: false
            referencedRelation: "pets"
            referencedColumns: ["id"]
          },
        ]
      }
      video_generations: {
        Row: {
          completed_at: string | null
          created_at: string | null
          dashscope_task_id: string | null
          duration: number | null
          error_message: string | null
          id: string
          metadata: Json
          original_images: string[] | null
          pet_id: string
          progress: number | null
          prompt: string
          resolution: string | null
          status: "pending" | "processing" | "completed" | "failed"
          style: string | null
          updated_at: string | null
          user_id: string
          video_url: string | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string | null
          dashscope_task_id?: string | null
          duration?: number | null
          error_message?: string | null
          id?: string
          metadata?: Json
          original_images?: string[] | null
          pet_id: string
          progress?: number | null
          prompt: string
          resolution?: string | null
          status?: "pending" | "processing" | "completed" | "failed"
          style?: string | null
          updated_at?: string | null
          user_id: string
          video_url?: string | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string | null
          dashscope_task_id?: string | null
          duration?: number | null
          error_message?: string | null
          id?: string
          metadata?: Json
          original_images?: string[] | null
          pet_id?: string
          progress?: number | null
          prompt?: string
          resolution?: string | null
          status?: "pending" | "processing" | "completed" | "failed"
          style?: string | null
          updated_at?: string | null
          user_id?: string
          video_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "video_generations_pet_id_fkey"
            columns: ["pet_id"]
            isOneToOne: false
            referencedRelation: "pets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "video_generations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (Database["public"]["Tables"] & Database["public"]["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (Database["public"]["Tables"] &
        Database["public"]["Views"])
    ? (Database["public"]["Tables"] &
        Database["public"]["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof Database["public"]["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof Database["public"]["Tables"]
    ? Database["public"]["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof Database["public"]["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof Database["public"]["Tables"]
    ? Database["public"]["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof Database["public"]["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof Database["public"]["Enums"]
    ? Database["public"]["Enums"][PublicEnumNameOrOptions]
    : never