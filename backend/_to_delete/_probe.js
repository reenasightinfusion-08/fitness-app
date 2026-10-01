require('dotenv').config({path: process.cwd()+'/.env'});
const mongoose=require('mongoose');
const Routine=require('./models/Routine');require('./models/Stretch');
const {planPool}=require('./utils/dailyPlan');
(async()=>{
  await mongoose.connect(process.env.MONGODB_URI||process.env.MONGO_URI);
  const rs=await Routine.find({isActive:true}).populate('stretches.stretch');
  console.log('routines',rs.length);
  const u={painAreas:['neck','hamstrings','wrists'],goals:['flexibility'],noKneel:true,equipmentNone:true,equipment:[],flexibilityLevel:2,minutesPerDay:10};
  const pool=planPool(rs,u);
  console.log(pool.map(r=>`${r.name} ${Math.round(r.totalSeconds/60)}m ${r.level} eq=${r.equipment} areas=${r.areas}`));
  console.log('all:');rs.forEach(r=>console.log(r.name,Math.round(r.totalSeconds/60)+'m',r.level,'eq='+r.equipment,'areas='+r.areas,'tags='+r.tags));
  process.exit(0);
})().catch(e=>{console.log('ERR',e.message);process.exit(1)});
