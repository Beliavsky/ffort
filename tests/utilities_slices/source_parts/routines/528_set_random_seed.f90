subroutine set_random_seed(fixed,offset,nburn_random)
logical, intent(in)           :: fixed        ! if .true., use a fixed seed
integer, intent(in), optional :: offset       ! constant added to generated seeds
integer, intent(in), optional :: nburn_random ! # of variates of RANDOM_NUMBER to burn off
integer, parameter            :: nburn = 100, nseeds_max = 12, seeds_vec(nseeds_max) = [824514020,218904035,384790913, &
                                 510442021,939900036,939295695,826403327,935378387, &
                                 634734772,413176190,91069182,818551196]
integer                       :: i,iburn,nseeds,itime,offset_,nburn_random_
integer, allocatable          :: seed(:)
real(kind=dp)                 :: xran,xseed(nburn + nseeds_max)
nburn_random_ = 100
offset_ = 0
if (present(nburn_random)) nburn_random_ = nburn_random
if (present(offset)) offset_ = offset
call random_seed(size=nseeds)
allocate(seed(nseeds))
if (fixed) then
   if (nseeds > nseeds_max) then
      seed(:nseeds_max) = seeds_vec + offset_
      seed(nseeds_max + 1:) = 0 ! NAG says to set the remaining elements of the seed array to zero to indicate zero entropy
   else
      seed = seeds_vec(:nseeds) + offset_
   end if
else ! set seed based on current time
   call system_clock(itime)
   seed = itime
   call random_seed(put=seed)
   call random_number(xseed)
   do i=1,nseeds
      if (i <= nseeds_max) then
         seed(i) = xseed(nburn+i)*1000000000 + offset_
      else
         seed(i) = 0
      end if
   end do
end if
call random_seed(put=seed)
do iburn=1,nburn_random_
   call random_number(xran)
end do
end subroutine set_random_seed
!
