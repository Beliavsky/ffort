program independent_ranktwo
implicit none
integer :: aa(128,256),bb(256,128)
aa=1
bb=2
print *,size(aa),size(bb),aa(128,256),bb(256,128)
end program independent_ranktwo
