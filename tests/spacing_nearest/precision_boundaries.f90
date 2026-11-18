program focused
 implicit none
 real :: u4, x4(4), empty4(0), matrix4(2,2), dirs4(2,2)
 real(8) :: u8, tiny_s8, huge_s8, empty8(0)
 u4=nearest(0.0,1.0)
 u8=nearest(0.0_8,1.0)
 tiny_s8=tiny(0.0_8)
 huge_s8=huge(0.0_8)
 print *, 'spacing4',spacing(x=1.0)==2.0**(-23),spacing(-1.0)==2.0**(-23), &
 spacing(2.0)==2.0**(-22),spacing(0.0)==tiny(0.0),spacing(-0.0)==tiny(0.0), &
 spacing(u4)==tiny(0.0),spacing(tiny(0.0))==tiny(0.0)
 print *, 'spacing8',spacing(x=1.0_8)==2.0_8**(-52),spacing(-1.0_8)==2.0_8**(-52), &
 spacing(2.0_8)==2.0_8**(-51),spacing(0.0_8)==tiny(0.0_8),spacing(-0.0_8)==tiny(0.0_8), &
 spacing(u8)==tiny(0.0_8),spacing(tiny(0.0_8))==tiny(0.0_8)
 print *, 'nearest4',nearest(s=1.0_8,x=1.0)==1.0+2.0**(-23), &
 nearest(1.0,-1.0)==1.0-2.0**(-24),nearest(-1.0,1.0)==-1.0+2.0**(-24), &
 nearest(-1.0,-1.0)==-1.0-2.0**(-23),kind(nearest(1.0,1.0_8))==4
 print *, 'nearest8',nearest(s=1.0,x=1.0_8)==1.0_8+2.0_8**(-52), &
 nearest(1.0_8,-1.0)==1.0_8-2.0_8**(-53),nearest(-1.0_8,1.0)==-1.0_8+2.0_8**(-53), &
 nearest(-1.0_8,-1.0)==-1.0_8-2.0_8**(-52),kind(nearest(1.0_8,1.0))==8
 print *, 'zero4',u4>0.0,u4<tiny(0.0),nearest(-0.0,1.0)==u4,nearest(0.0,-1.0)==-u4, &
 nearest(u4,-1.0)==0.0,sign(1.0,nearest(-u4,1.0))==-1.0,nearest(u4,1.0)==2.0*u4
 print *, 'zero8',u8>0.0_8,u8<tiny(0.0_8),nearest(-0.0_8,1.0)==u8,nearest(0.0_8,-1.0)==-u8, &
 nearest(u8,-1.0)==0.0_8,sign(1.0_8,nearest(-u8,1.0))==-1.0_8,nearest(u8,1.0)==2.0_8*u8
 print *, 'boundaries4',u4==tiny(0.0)*epsilon(0.0),nearest(tiny(0.0),-1.0)==tiny(0.0)-u4, &
 spacing(2.0**(-103))==tiny(0.0),spacing(2.0**(-102))==2.0*tiny(0.0), &
 spacing(huge(0.0))==2.0**104,nearest(huge(0.0),-1.0)==huge(0.0)-2.0**104
 print *, 'boundaries8',u8==tiny(0.0_8)*epsilon(0.0_8),nearest(tiny(0.0_8),-1.0)==tiny(0.0_8)-u8, &
 spacing(2.0_8**(-970))==tiny(0.0_8),spacing(2.0_8**(-969))==2.0_8*tiny(0.0_8), &
 spacing(huge(0.0_8))==2.0_8**971,nearest(huge(0.0_8),-1.0)==huge(0.0_8)-2.0_8**971
 print *, 'mixed-s',nearest(1.0,tiny_s8)==nearest(1.0,1.0), &
 nearest(1.0,-tiny_s8)==nearest(1.0,-1.0),nearest(1.0,huge_s8)==nearest(1.0,1.0)
 x4=[1.0,2.0,-1.0,-2.0]
 print *, 'array',all(spacing(x4)==[2.0**(-23),2.0**(-22),2.0**(-23),2.0**(-22)]), &
 all(nearest(x4,1.0_8)>x4),all(nearest(1.0,[-1.0_8,1.0_8])==[1.0-2.0**(-24),1.0+2.0**(-23)])
 matrix4=reshape(x4,[2,2]); dirs4=reshape([-1.0,1.0,-1.0,1.0],[2,2])
 print *, 'matrix',all(shape(nearest(matrix4,dirs4))==[2,2]), &
 all(nearest(matrix4,dirs4)==reshape([nearest(1.0,-1.0),nearest(2.0,1.0), &
 nearest(-1.0,-1.0),nearest(-2.0,1.0)],[2,2]))
 print *, 'empty',size(spacing(empty4))==0,kind(spacing(empty4))==4, &
 size(nearest(empty4,1.0_8))==0,kind(nearest(empty4,1.0_8))==4, &
 size(nearest(1.0_8,empty4))==0,kind(nearest(1.0_8,empty4))==8, &
 size(nearest(empty4,empty8))==0,kind(nearest(empty4,empty8))==4
end
