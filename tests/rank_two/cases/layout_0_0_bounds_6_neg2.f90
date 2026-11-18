program independent_ranktwo
implicit none
integer :: aa(6:5,-2:-3),bb(0,0),i,j
do j=-2,-3
      do i=6,5
        aa(i,j)=100*j+i
      end do
    end do
    print *, size(aa),size(aa,1),size(aa,2)
    print *, lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
    print *, aa
    bb=aa+7
    print *, bb
    print *, size(aa+1,1),size(aa+1,2),lbound(aa+1,1),ubound(aa+1,1)
    print *, lbound(aa+1,2),ubound(aa+1,2)

end program independent_ranktwo
