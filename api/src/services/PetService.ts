import { supabase } from '../config/supabase';
import { ErrorTypes } from '../middleware/errorHandler';
import type { 
  Pet, 
  CreatePetInput, 
  UpdatePetInput,
  PetWithDetails,
  PetFilters,
  PaginationParams,
  PaginatedResponse
} from '../models';

export class PetService {
  async createPet(userId: string, input: CreatePetInput): Promise<Pet> {
    try {
      const { data, error } = await supabase
        .from('pets')
        .insert({
          ...input,
          user_id: userId
        })
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to create pet');
      }

      return data;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.INTERNAL_ERROR('Failed to create pet');
    }
  }

  async getPetById(id: string, userId: string): Promise<Pet> {
    try {
      const { data, error } = await supabase
        .from('pets')
        .select('*')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        throw ErrorTypes.NOT_FOUND('Pet not found');
      }

      return data;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to get pet');
    }
  }

  async getPetsByUserId(
    userId: string,
    pagination?: PaginationParams,
    filters?: PetFilters
  ): Promise<PaginatedResponse<Pet>> {
    try {
      let query = supabase
        .from('pets')
        .select('*', { count: 'exact' })
        .eq('user_id', userId);

      // 应用过滤器
      if (filters?.type) {
        query = query.eq('type', filters.type as any);
      }
      if (filters?.breed) {
        query = query.ilike('breed', `%${filters.breed}%`);
      }
      if (filters?.age_min) {
        query = query.gte('age', filters.age_min);
      }
      if (filters?.age_max) {
        query = query.lte('age', filters.age_max);
      }

      // 应用排序
      const sortBy = pagination?.sortBy || 'created_at';
      const sortOrder = pagination?.sortOrder || 'desc';
      query = query.order(sortBy, { ascending: sortOrder === 'asc' });

      // 应用分页
      if (pagination?.page && pagination?.limit) {
        const offset = (pagination.page - 1) * pagination.limit;
        query = query.range(offset, offset + pagination.limit - 1);
      }

      const { data, error, count } = await query;

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to get pets');
      }

      return {
        data: data || [],
        pagination: {
          page: pagination?.page || 1,
          limit: pagination?.limit || data?.length || 0,
          total: count || 0,
          totalPages: pagination?.limit ? Math.ceil((count || 0) / pagination.limit) : 1
        }
      };
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to get pets');
    }
  }

  async updatePet(id: string, userId: string, updates: UpdatePetInput): Promise<Pet> {
    try {
      // 验证宠物是否存在且属于用户
      await this.getPetById(id, userId);

      const { data, error } = await supabase
        .from('pets')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to update pet');
      }

      return data;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to update pet');
    }
  }

  async deletePet(id: string, userId: string): Promise<void> {
    try {
      // 验证宠物是否存在且属于用户
      await this.getPetById(id, userId);

      const { error } = await supabase
        .from('pets')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);

      if (error) {
        throw ErrorTypes.DATABASE_ERROR('Failed to delete pet');
      }
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to delete pet');
    }
  }

  async getPetWithDetails(id: string, userId: string): Promise<PetWithDetails> {
    try {
      const { data, error } = await supabase
        .from('pets')
        .select(`
          *,
          letters:letters(count),
          video_generations:video_generations(count)
        `)
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        throw ErrorTypes.NOT_FOUND('Pet not found');
      }

      return data as PetWithDetails;
    } catch (error) {
      if (error instanceof Error && 'statusCode' in error) {
        throw error;
      }
      throw ErrorTypes.DATABASE_ERROR('Failed to get pet details');
    }
  }
}

export default new PetService();