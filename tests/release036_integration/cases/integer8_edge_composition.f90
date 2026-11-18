program main
implicit none
integer(8)::lo,hi,a(2,2)
hi=huge(0_8)
lo=-hi-1_8
a=reshape([lo,hi,-1_8,0_8],[2,2])
write(*,'("edges:",4(1x,i0))')sign(lo,-1_8),dim(hi,hi),dim(lo,0_8),dim(hi,0_8)
write(*,'("gather:",4(1x,i0))')sign(a([2,1],:),-1_8)
end program
