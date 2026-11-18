program independent_ranktwo
implicit none
integer :: aa(256,256)
aa=3
aa(256,256)=7
print *,size(aa),aa(1,1),aa(256,256)
end program independent_ranktwo
