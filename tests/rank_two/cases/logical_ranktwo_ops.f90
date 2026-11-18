program independent_ranktwo
implicit none
logical :: aa(2,2),bb(-1:0,4:5)
aa=.false.
aa(2,1)=.true.
aa(1,2)=.true.
bb=.not.aa
print *, aa,bb,aa.and.bb,aa.or.bb,aa.eqv.bb,aa.neqv.bb
end program independent_ranktwo
