program independent_ranktwo
implicit none
integer :: aa(0,3),bb(0,3),uninit
aa=bb+uninit
print *,size(aa),size(aa,1),size(aa,2)
end program independent_ranktwo
