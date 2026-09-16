import { z } from "zod";
export const randomContentSchema=z.object({template:z.enum(["rising-sun","heritage","modern-lines"]),format:z.enum(["whatsapp","instagram"])});
export const downloadSchema=z.object({phone:z.string().transform(v=>v.replace(/\D/g,"")),templateId:z.string().min(1).max(80),contentId:z.string().uuid(),format:z.enum(["whatsapp","instagram"])}).refine(v=>/^(?:91)?[6-9]\d{9}$/.test(v.phone),{message:"Enter a valid Indian mobile number.",path:["phone"]});
export const contentSchema=z.object({title:z.string().trim().min(2).max(100),contentText:z.string().trim().min(5).max(500),isActive:z.boolean()});
