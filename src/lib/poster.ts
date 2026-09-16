export type PosterFormat="whatsapp"|"instagram";
export type TemplateKey="rising-sun"|"heritage"|"modern-lines";
export const FORMATS={whatsapp:{label:"WhatsApp Portrait",width:1080,height:1920,ratio:"9:16"},instagram:{label:"Instagram Portrait",width:1080,height:1350,ratio:"4:5"}} as const;
export const TEMPLATES=[{id:"rising-sun",name:"எழுச்சி",note:"Bold red, black & gold"},{id:"heritage",name:"மரபு",note:"Editorial cream & crimson"},{id:"modern-lines",name:"முன்னேற்றம்",note:"Clean geometric layout"}] as const;
export type RenderInput={fullName:string;designation:string;approvedContent:string;photoUrl:string;symbolUrl?:string|null;format:PosterFormat;template:TemplateKey};

function wrap(ctx:CanvasRenderingContext2D,text:string,maxWidth:number){const words=text.trim().split(/\s+/),lines:string[]=[];let line="";for(const word of words){const next=line?`${line} ${word}`:word;if(ctx.measureText(next).width>maxWidth&&line){lines.push(line);line=word}else line=next}if(line)lines.push(line);return lines}
function load(url:string){return new Promise<HTMLImageElement>((resolve,reject)=>{const el=new Image();el.crossOrigin="anonymous";el.onload=()=>resolve(el);el.onerror=reject;el.src=url})}
function cover(ctx:CanvasRenderingContext2D,img:HTMLImageElement,x:number,y:number,w:number,h:number){const scale=Math.max(w/img.width,h/img.height),sw=w/scale,sh=h/scale;ctx.drawImage(img,(img.width-sw)/2,(img.height-sh)/2,sw,sh,x,y,w,h)}
function fitText(ctx:CanvasRenderingContext2D,text:string,maxWidth:number,maxHeight:number,startSize:number,minSize:number){let size=startSize,lines:string[]=[];while(size>=minSize){ctx.font=`800 ${size}px "Noto Sans Tamil",Latha,Vijaya,sans-serif`;lines=wrap(ctx,text,maxWidth);const lineHeight=size*1.48;if(lines.length*lineHeight<=maxHeight)return{size,lines,lineHeight};size-=2}ctx.font=`800 ${minSize}px "Noto Sans Tamil",Latha,Vijaya,sans-serif`;lines=wrap(ctx,text,maxWidth);return{size:minSize,lines,lineHeight:minSize*1.48}}

export async function renderPoster(canvas:HTMLCanvasElement,input:RenderInput){
 const {width:w,height:h}=FORMATS[input.format];canvas.width=w;canvas.height=h;const ctx=canvas.getContext("2d");if(!ctx)throw new Error("Canvas unavailable");
 const photo=await load(input.photoUrl),modern=input.template==="modern-lines",heritage=input.template==="heritage",dark=!modern&&!heritage,accent=heritage?"#8e1c24":"#b42327",paper=heritage?"#f2e8d5":modern?"#f6f2e9":"#171411",ink=dark?"#ffffff":"#171411";
 ctx.fillStyle=paper;ctx.fillRect(0,0,w,h);ctx.fillStyle=accent;
 if(modern){ctx.fillRect(0,0,w,h*.055);ctx.fillRect(0,h*.94,w,h*.06)}else{ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(w,0);ctx.lineTo(w,h*.12);ctx.lineTo(0,h*.18);ctx.closePath();ctx.fill()}
 if(heritage){ctx.strokeStyle=accent;ctx.lineWidth=6;ctx.strokeRect(34,34,w-68,h-68)}

 const margin=w*.09,messageTop=h*.16,messageBottom=h*.61,messageHeight=messageBottom-messageTop;
 ctx.textAlign="center";ctx.textBaseline="middle";ctx.fillStyle=ink;
 const fitted=fitText(ctx,input.approvedContent,w-margin*2,messageHeight,input.format==="whatsapp"?76:64,input.format==="whatsapp"?38:32);
 const textHeight=fitted.lines.length*fitted.lineHeight,startY=messageTop+(messageHeight-textHeight)/2+fitted.lineHeight/2;
 fitted.lines.forEach((line,i)=>ctx.fillText(line,w/2,startY+i*fitted.lineHeight));
 ctx.fillStyle="#d49a29";ctx.fillRect(w*.39,messageBottom+h*.015,w*.22,8);

 const blockTop=h*.66,blockBottom=h*.925,blockH=blockBottom-blockTop,photoSize=Math.min(w*.34,blockH*.82),px=margin,py=blockTop+(blockH-photoSize)/2;
 ctx.save();ctx.beginPath();if(heritage)ctx.ellipse(px+photoSize/2,py+photoSize/2,photoSize/2,photoSize/2,0,0,Math.PI*2);else ctx.roundRect(px,py,photoSize,photoSize,38);ctx.clip();cover(ctx,photo,px,py,photoSize,photoSize);ctx.restore();ctx.strokeStyle="#d49a29";ctx.lineWidth=10;if(heritage){ctx.beginPath();ctx.ellipse(px+photoSize/2,py+photoSize/2,photoSize/2,photoSize/2,0,0,Math.PI*2);ctx.stroke()}else ctx.strokeRect(px,py,photoSize,photoSize);

 const textX=px+photoSize+(w*.055),textW=w-margin-textX;ctx.textAlign="left";ctx.fillStyle=accent;ctx.font=`900 ${input.format==="whatsapp"?60:48}px "Noto Sans Tamil",Latha,sans-serif`;
 const nameLines=wrap(ctx,input.fullName.trim(),textW).slice(0,2),nameLH=input.format==="whatsapp"?78:62,nameY=blockTop+blockH*.39-(nameLines.length-1)*nameLH/2;nameLines.forEach((line,i)=>ctx.fillText(line,textX,nameY+i*nameLH));
 ctx.fillStyle=dark?"#f7f1e5":"#39322b";ctx.font=`600 ${input.format==="whatsapp"?34:28}px "Noto Sans Tamil",Latha,sans-serif`;const designationLines=wrap(ctx,input.designation.trim(),textW).slice(0,3),desY=nameY+nameLines.length*nameLH+18;designationLines.forEach((line,i)=>ctx.fillText(line,textX,desY+i*(input.format==="whatsapp"?50:42)));
 if(input.symbolUrl){try{const symbol=await load(input.symbolUrl);ctx.drawImage(symbol,w-180,44,120,120)}catch{}}
 ctx.textAlign="center";ctx.fillStyle=dark?"#81766a":"#9b8e7d";ctx.font="500 23px system-ui,sans-serif";ctx.fillText("ADMIN-APPROVED CONTENT",w/2,h-48);
}
