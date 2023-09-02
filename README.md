# MealTracker
This is a meal tracking iOS app. Features include adding meals to, deleting meals from, searching, and sorting a list of meals. Users can also mark whether meals have been eaten and edit their meals.
When adding meals, it is possible to either manually add a meal or have AI generate a meal from a basic description. 
Meals are generated by AI through calling the GPT4 API to return a title and description for a meal, and this description is passed to the DALLE 2 API to generate an image of the meal. Meals are saved locally using Core Data so that the list of meals is persisted across sessions.



Here is a video of the application:
https://www.youtube.com/watch?v=H-FNpvRcbR4

Here are some images:
<br></br>
<img src="https://github.com/isaacrestrick/MealTracker/blob/main/images_for_readme/all_meals.png" width="300" height="650">
