pure function num_good_rows(good,min_good,max_bad) result(ngood)
! print the number of rows of good(:,:) that have at least min_good .true. values and no more than max_bad .false. values
logical, intent(in)           :: good(:,:)
integer, intent(in), optional :: min_good,max_bad
integer                       :: ngood
ngood = count(count(good,2)        >= default(1,min_good) .and. &
        count(.not. good,2)        <= default(size(good,2)-1,max_bad))
end function num_good_rows
!
